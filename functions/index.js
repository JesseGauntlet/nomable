const { onObjectFinalized } = require('firebase-functions/v2/storage');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');
const os = require('os');
const path = require('path');
const fs = require('fs');
const { SecretManagerServiceClient } = require('@google-cloud/secret-manager');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const { Storage } = require('@google-cloud/storage');

const ffmpeg = require('fluent-ffmpeg');
const ffmpegPath = require('ffmpeg-static');
// Tell fluent-ffmpeg where to find the ffmpeg binary
ffmpeg.setFfmpegPath(ffmpegPath);

admin.initializeApp();
const myProject = process.env.GOOGLE_CLOUD_PROJECT || 'foodtalk-f468d';
// Initialize clients
const secretManager = new SecretManagerServiceClient({
  projectId: myProject
});
const db = admin.firestore();

const storage = new Storage();

async function getGeminiKey() {
  const [version] = await secretManager.accessSecretVersion({
    name: `projects/${myProject}/secrets/Gemini/versions/latest`
  });
  return version.payload.data.toString();
}

async function analyzeWithGemini(videoUrl) {
  const apiKey = await getGeminiKey();
  const genAI = new GoogleGenerativeAI(apiKey);
  const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });

  try {
    // Download video from GCS
    const bucket = storage.bucket(videoUrl.split('/')[2]);
    const fileName = videoUrl.split('/').slice(3).join('/');
    const tempFilePath = path.join(os.tmpdir(), path.basename(videoUrl));
    
    try {
      await bucket.file(fileName).download({
        destination: tempFilePath
      });
    } catch (downloadError) {
      console.error('Error downloading video:', downloadError);
      throw downloadError;
    }
    
    // Read file as base64
    let videoBuffer;
    try {
      videoBuffer = await fs.promises.readFile(tempFilePath);
    } catch (readError) {
      console.error('Error reading video file:', readError);
      throw readError;
    }
    
    let base64Video;
    try {
      base64Video = videoBuffer.toString('base64');
    } catch (base64Error) {
      console.error('Error converting video to base64:', base64Error);
      throw base64Error;
    }
    
    // Clean up temp file
    try {
      await fs.promises.unlink(tempFilePath);
    } catch (unlinkError) {
      console.warn('Error cleaning up temporary file:', unlinkError);
      // Non-critical error, continue processing
    }

    const prompt = `
      Video analysis, returning primary food tags (e.g. pizza, and or italian,
          but not dough or tomato sauce), detailed description of the food in the
          video, quantified ingredients, detailed step by step recipe with
          quantified ingredient usage, and content moderation
          (if topic is_food_related, or topic is_nsfw, also add a "reason"
          field that states why content moderation failed).

          Format your response as JSON with these fields:
          {
            "video_id": "unique_video_identifier",
            "topic": "food_related",
            "primary_food_tags": ["pizza", "italian"],
            "detailed_food_description": "A pepperoni pizza with a thick crust...",
            "quantified_ingredients": [
              {"ingredient": "pizza dough", "quantity": "500g"}
            ],
            "detailed_step_by_step_recipe": [
              {"step": 1, "instruction": "Preheat oven to 220°C (425°F)."}
            ],
            "content_moderation": {
              "is_food_related": true,
              "is_nsfw": false,
              "reason": null
            }
          }
    `;
    
    const parts = [
      {
        inlineData: {
          mimeType: 'video/mp4',
          data: base64Video
        },
      },
      { text: prompt },
    ];
    
    const result = await model.generateContent({
      contents: [{ role: 'user', parts }]
    });
    
    try {
      const responseText = result.response.text();
      
      // Extract JSON from markdown code block if present
      const jsonMatch = responseText.match(/```(?:json)?\s*(\{[\s\S]*\})\s*```/);
      const jsonStr = jsonMatch ? jsonMatch[1] : responseText;
      
      return JSON.parse(jsonStr);
    } catch (parseError) {
      console.error('Error parsing Gemini response:', parseError, 'Response text:', result.response.text());
      return { tags: [], description: 'Failed to analyze video due to parsing error.' };
    }
  } catch (error) {
    console.error('Error analyzing video:', error);
    return { tags: [], description: 'Failed to analyze video.' };
  }
}

// Cloud Function triggered on finalization (upload) of a storage object
exports.generatePreviewV2 = onObjectFinalized({
  timeoutSeconds: 300,
  memory: '2GiB',
}, async (event) => {
  // Skip processing if the file is not in the videos directory
  if (!event.data.name.startsWith('videos/')) {
    return null;
  }

  // Read file metadata from the event
  const fileBucket = event.data.bucket;
  const filePath = event.data.name;
  const contentType = event.data.contentType;

  // Parse paths early
  const pathParts = filePath.split('/');
  if (pathParts.length < 3) {
    console.error('Invalid file path structure:', filePath);
    return null;
  }

  // Extract userId and define destinations early
  const userId = pathParts[1];
  const fileName = path.basename(filePath);
  const previewFileName = fileName.replace('.mp4', '_preview.mp4');
  const thumbnailFileName = fileName.replace('.mp4', '_thumb.jpg');
  const hlsBaseName = fileName.replace('.mp4', '');
  const previewDestination = `previews/${userId}/${previewFileName}`;
  const thumbnailDestination = `thumbnails/${userId}/${thumbnailFileName}`;
  const hlsDestinationBase = `hls/${userId}/${hlsBaseName}`;

  // Skip processing if the file is already a preview
  if (filePath.includes('_preview.mp4')) {
    console.log('File is already a preview. Skipping transcoding.');
    return null;
  }

  // Make sure the uploaded file is a video
  if (!contentType.startsWith('video/')) {
    console.log('Uploaded file is not a video. Exiting function.');
    return null;
  }

  // Download the video file to a temporary directory
  const tempFilePath = path.join(os.tmpdir(), fileName);
  const bucket = admin.storage().bucket(fileBucket);
  
  console.log('Downloading video:', filePath);
  await bucket.file(filePath).download({ destination: tempFilePath });
  console.log('Downloaded video to:', tempFilePath);

  // Define output file paths for the preview video and thumbnail
  const tempPreviewFilePath = path.join(os.tmpdir(), previewFileName);
  const tempThumbnailPath = path.join(os.tmpdir(), thumbnailFileName);
  const tempHlsDir = path.join(os.tmpdir(), 'hls', hlsBaseName);
  const tempHlsManifest = path.join(tempHlsDir, 'master.m3u8');

  // Ensure HLS directory exists
  try {
    fs.mkdirSync(tempHlsDir, { recursive: true });
  } catch (mkdirError) {
    console.error('Error creating HLS directory:', mkdirError);
    return null;
  }

  try {
    // Run all processing in parallel
    console.log('Starting parallel video processing');
    await Promise.all([
      // Thumbnail generation
      new Promise((resolve, reject) => {
        console.log('Generating thumbnail...');
        ffmpeg(tempFilePath)
          .screenshots({
            timestamps: [1],
            filename: thumbnailFileName,
            folder: os.tmpdir(),
            size: '480x?',
            quality: 90
          })
          .on('end', async () => {
            console.log('Thumbnail generated successfully');
            try {
              // Upload thumbnail immediately
              await bucket.upload(tempThumbnailPath, {
                destination: thumbnailDestination,
                metadata: {
                  contentType: 'image/jpeg',
                  metadata: { originalVideo: filePath }
                },
              });
              await bucket.file(thumbnailDestination).makePublic();
              // Clean up thumbnail file
              fs.unlinkSync(tempThumbnailPath);
              console.log('Thumbnail uploaded and cleaned up');
            } catch (err) {
              console.error('Error uploading thumbnail:', err);
            }
            resolve();
          })
          .on('error', (err) => {
            console.error('Error generating thumbnail:', err);
            reject(err);
          });
      }),
      // Preview video generation
      new Promise((resolve, reject) => {
        console.log('Starting preview video transcoding...');
        ffmpeg(tempFilePath)
          .outputOptions([
            '-vf', 'scale=-2:480',
            '-c:a', 'copy',
            '-c:v', 'libx264',
            '-crf', '28',
            '-preset', 'medium'
          ])
          .output(tempPreviewFilePath)
          .on('progress', (progress) => {
            console.log(`Preview Processing: ${progress.percent}% done`);
          })
          .on('end', async () => {
            console.log('Preview video created successfully');
            try {
              // Upload preview immediately
              await bucket.upload(tempPreviewFilePath, {
                destination: previewDestination,
                metadata: {
                  contentType: 'video/mp4',
                  metadata: { originalVideo: filePath }
                },
              });
              await bucket.file(previewDestination).makePublic();
              // Clean up preview file
              fs.unlinkSync(tempPreviewFilePath);
              console.log('Preview uploaded and cleaned up');
            } catch (err) {
              console.error('Error uploading preview:', err);
            }
            resolve();
          })
          .on('error', (err) => {
            console.error('Error during preview transcoding:', err);
            reject(err);
          })
          .run();
      }),
      // HLS transcoding
      new Promise((resolve, reject) => {
        console.log('Starting HLS transcoding...');
        ffmpeg(tempFilePath)
          .outputOptions([
            '-hls_time', '6',
            '-hls_list_size', '0',
            '-hls_segment_type', 'mpegts',
            '-hls_segment_filename', path.join(tempHlsDir, 'segment_%03d.ts'),
            '-c:v', 'libx264',
            '-crf', '23',
            '-preset', 'fast',
            '-vf', 'scale=-2:720',
            '-c:a', 'aac',
            '-b:a', '128k',
            '-master_pl_name', 'master.m3u8',
            '-f', 'hls'
          ])
          .output(path.join(tempHlsDir, 'playlist.m3u8'))
          .on('progress', (progress) => {
            console.log(`HLS Processing: ${progress.percent}% done`);
          })
          .on('end', async () => {
            console.log('HLS streams created successfully');
            try {
              // Upload HLS files immediately
              const hlsFiles = fs.readdirSync(tempHlsDir);
              console.log('Uploading HLS streams...');
              await Promise.all([
                ...hlsFiles.map(file => 
                  bucket.upload(path.join(tempHlsDir, file), {
                    destination: `${hlsDestinationBase}/${file}`,
                    metadata: {
                      contentType: file.endsWith('.m3u8') ? 'application/x-mpegURL' : 'video/MP2T',
                      metadata: { originalVideo: filePath }
                    },
                  })
                )
              ]);

              // Make HLS files publicly accessible
              await Promise.all(
                hlsFiles.map(file => 
                  bucket.file(`${hlsDestinationBase}/${file}`).makePublic()
                )
              );

              // Clean up HLS directory
              fs.rmSync(tempHlsDir, { recursive: true, force: true });
              console.log('HLS files uploaded and cleaned up');
            } catch (err) {
              console.error('Error uploading HLS files:', err);
            }
            resolve();
          })
          .on('error', (err) => {
            console.error('Error during HLS transcoding:', err);
            reject(err);
          })
          .run();
      })
    ]);

    const previewUrl = `https://storage.googleapis.com/${fileBucket}/previews/${userId}/${previewFileName}`;
    const thumbnailUrl = `https://storage.googleapis.com/${fileBucket}/thumbnails/${userId}/${thumbnailFileName}`;
    const hlsUrl = `https://storage.googleapis.com/${fileBucket}/${hlsDestinationBase}/playlist.m3u8`;
    console.log('Files are publicly available at:', { previewUrl, thumbnailUrl });
    console.log('HLS URL:', hlsUrl);

    // Update Firestore if postId is provided
    if (event.data.metadata && event.data.metadata.postId) {
      const postId = event.data.metadata.postId;
      console.log('Updating Firestore document:', postId);
      const postRef = admin.firestore().collection('posts').doc(postId);
      
      try {
        await postRef.update({
          previewUrl,
          thumbnailUrl,
          hlsUrl: `https://storage.googleapis.com/${fileBucket}/${hlsDestinationBase}/playlist.m3u8`,
          previewGenerated: true,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log('Successfully updated Firestore document');
      } catch (error) {
        console.error('Error updating Firestore document:', error);
        // Even if Firestore update fails, we don't throw since files are uploaded
        // Client can still access the files via the URLs
      }
    }
  } catch (error) {
    console.error('Error in processing:', error);
    // Clean up any files that might have been created before the error
    try {
      if (fs.existsSync(tempFilePath)) fs.unlinkSync(tempFilePath);
      if (fs.existsSync(tempPreviewFilePath)) fs.unlinkSync(tempPreviewFilePath);
      if (fs.existsSync(tempThumbnailPath)) fs.unlinkSync(tempThumbnailPath);
      if (fs.existsSync(tempHlsDir)) {
        fs.rmSync(tempHlsDir, { recursive: true, force: true });
      }
    } catch (cleanupError) {
      console.error('Error during cleanup after failure:', cleanupError);
    }
    return null;
  }

  // Clean up temporary files
  console.log('Cleaning up temporary files');
  try {
    // Only delete files that still exist
    if (fs.existsSync(tempFilePath)) {
      fs.unlinkSync(tempFilePath);
    }
    if (fs.existsSync(tempPreviewFilePath)) {
      fs.unlinkSync(tempPreviewFilePath);
    }
    if (fs.existsSync(tempThumbnailPath)) {
      fs.unlinkSync(tempThumbnailPath);
    }
    if (fs.existsSync(tempHlsDir)) {
      fs.rmSync(tempHlsDir, { recursive: true, force: true });
    }
  } catch (cleanupError) {
    console.error('Error during final cleanup:', cleanupError);
    // Don't throw since processing is complete
  }

  console.log('Processing complete');
  return null;
});

// Cloud Function to handle group vote initiation
exports.initiateGroupVoteV2 = onDocumentCreated('groups/{groupId}/votes/{voteId}', async (event) => {
  try {
    const { groupId } = event.params;
    const voteData = event.data.data();
    
    // Get group members
    const groupDoc = await admin.firestore()
      .collection('groups')
      .doc(groupId)
      .get();
    
    if (!groupDoc.exists) {
      console.error('Group not found:', groupId);
      return null;
    }

    const memberIds = groupDoc.data().members || [];
    if (memberIds.length === 0) {
      console.log('No members in group:', groupId);
      return null;
    }

    // Get FCM tokens for all members
    const membersSnapshot = await admin.firestore()
      .collection('users')
      .where(admin.firestore.FieldPath.documentId(), 'in', memberIds)
      .get();

    // Reset all member swipe counts in a batch
    const batch = admin.firestore().batch();
    membersSnapshot.docs.forEach(doc => {
      batch.update(doc.ref, { 
        swipeCount: 0,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    // Commit the batch update
    await batch.commit();

    // Collect FCM tokens and maintain mapping with user document reference for potential cleanup
    const tokensData = membersSnapshot.docs.reduce((acc, doc) => {
      const token = doc.data().fcmToken;
      if (token) {
        acc.push({ token, ref: doc.ref });
      }
      return acc;
    }, []);
    const tokens = tokensData.map(item => item.token);

    if (tokens.length === 0) {
      console.log('No valid FCM tokens found for group members');
      return null;
    }

    // Create the message for all tokens
    const message = {
      tokens: tokens,
      notification: {
        title: "It's Froupin' time!",
        body: `The ${groupDoc.data().name} group started a vote, swipe now!`,
      },
      android: {
        notification: {
          channelId: 'group_vote_channel',
          priority: 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
      data: {
        type: 'group_vote',
        groupId: groupId,
      },
    };

    // Send notifications using the new sendEachForMulticast method
    const response = await admin.messaging().sendEachForMulticast(message);
    console.log('Successfully sent messages:', response.successCount);
    console.log('Failed messages:', response.failureCount);
    // Added detailed logging for each failed notification response; also clean up invalid tokens from Firestore
    const cleanupPromises = [];
    if (response.failureCount > 0) {
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          console.error(`Notification ${idx} failed: ${resp.error}`);
          if (resp.error && resp.error.message && resp.error.message.includes("Requested entity was not found")) {
            // Remove the invalid token from the corresponding user's document in Firestore
            cleanupPromises.push(tokensData[idx].ref.update({ fcmToken: admin.firestore.FieldValue.delete() }));
          }
        }
      });
    }
    if (cleanupPromises.length > 0) {
      await Promise.all(cleanupPromises);
    }
    // Update vote document with completion status
    await event.data.ref.update({
      status: 'completed',
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
      memberCount: memberIds.length,
      notificationsSent: response.successCount,
      notificationsFailed: response.failureCount
    });

    return { 
      success: true, 
      notificationsSent: response.successCount,
      notificationsFailed: response.failureCount
    };
  } catch (error) {
    console.error('Error in initiateGroupVote:', error);
    // Update vote document with error status
    await event.data.ref.update({
      status: 'error',
      error: error.message,
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return null;
  }
});

// Cloud Function to process videos with AI
exports.processVideoAI = onObjectFinalized({
  timeoutSeconds: 300,
  memory: '2GiB',
  location: 'us-central1',
  eventFilters: {
    path: {
      value: '/videos/',
      matchType: 'prefix'
    }
  }
}, async (event) => {
  const file = event.data;

  // Skip if not video
  if (!file.contentType?.startsWith('video/')) {
    console.log('Not a video file, skipping');
    return null;
  }

  // Check metadata
  const metadata = file.metadata || {};
  if (metadata.useAI !== 'true' || !metadata.postId) {
    console.log('Skipping AI processing, useAI =', metadata.useAI, 
                'postId =', metadata.postId);
    return null;
  }

  try {
    // Generate GCS URL
    const videoUrl = `gs://${file.bucket}/${file.name}`;
    
    // Process with Gemini
    const aiResults = await analyzeWithGemini(videoUrl);
    
    // Update Firestore
    await db.collection('posts').doc(metadata.postId).update({
      foodTags: aiResults.primary_food_tags || [],
      description: aiResults.detailed_food_description || '',
      recipe: aiResults.detailed_step_by_step_recipe || [],
      ingredients: aiResults.quantified_ingredients || [],
      ai_processed: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log(`Successfully processed video ${metadata.postId} with AI`);
    return null;

  } catch (error) {
    console.error('Error:', error);
    if (metadata.postId) {
      await db.collection('posts').doc(metadata.postId).update({
        ai_processed: false,
        ai_error: error.message,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }
    return null;
  }
}); 