const functions = require('firebase-functions');
const admin = require('firebase-admin');
const os = require('os');
const path = require('path');
const fs = require('fs');

const ffmpeg = require('fluent-ffmpeg');
const ffmpegPath = require('ffmpeg-static');
// Tell fluent-ffmpeg where to find the ffmpeg binary
ffmpeg.setFfmpegPath(ffmpegPath);

admin.initializeApp();

// Cloud Function triggered on finalization (upload) of a storage object
exports.generatePreview = functions
  .runWith({
    // Ensure the function has enough memory and time to process videos
    timeoutSeconds: 300,
    memory: '1GB'
  })
  .storage
  .bucket()
  .object('/videos/{userId}/{fileName}')
  .onFinalize(async (object) => {
    // Read file metadata from the event
    const fileBucket = object.bucket;
    const filePath = object.name;
    const contentType = object.contentType;

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
    const fileName = path.basename(filePath);
    const tempFilePath = path.join(os.tmpdir(), fileName);
    const bucket = admin.storage().bucket(fileBucket);
    
    console.log('Downloading video:', filePath);
    await bucket.file(filePath).download({ destination: tempFilePath });
    console.log('Downloaded video to:', tempFilePath);

    // Define output file paths for the preview video and thumbnail
    const previewFileName = fileName.replace('.mp4', '_preview.mp4');
    const thumbnailFileName = fileName.replace('.mp4', '_thumb.jpg');
    const hlsBaseName = fileName.replace('.mp4', '');
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
      // Generate thumbnail from the first frame
      console.log('Generating thumbnail...');
      await new Promise((resolve, reject) => {
        ffmpeg(tempFilePath)
          .screenshots({
            timestamps: [1], // Take screenshot at 1 second to avoid black frames
            filename: thumbnailFileName,
            folder: os.tmpdir(),
            size: '480x270', // 16:9 aspect ratio thumbnail
            quality: 90 // High quality JPEG
          })
          .on('end', () => {
            console.log('Thumbnail generated successfully');
            resolve();
          })
          .on('error', (err) => {
            console.error('Error generating thumbnail:', err);
            reject(err);
          });
      });

      // Generate HLS streams
      console.log('Starting HLS transcoding...');
      await new Promise((resolve, reject) => {
        ffmpeg(tempFilePath)
          .outputOptions([
            // HLS Specific settings
            '-hls_time', '6',        // 6 second segment duration
            '-hls_list_size', '0',   // Keep all segments in the playlist
            '-hls_segment_type', 'mpegts',  // Use .ts segments
            '-hls_segment_filename', path.join(tempHlsDir, 'segment_%03d.ts'),
            // Video settings
            '-c:v', 'libx264',     // Use H.264 codec
            '-crf', '23',          // Constant rate factor (quality)
            '-preset', 'fast',     // Encoding speed preset
            '-vf', 'scale=-2:720', // Scale to 720p maintaining aspect ratio
            // Audio settings
            '-c:a', 'aac',         // AAC audio codec
            '-b:a', '128k',        // Audio bitrate
            '-master_pl_name', 'master.m3u8',
            '-f', 'hls'
          ])
          .output(path.join(tempHlsDir, 'playlist.m3u8'))
          .on('progress', (progress) => {
            console.log(`HLS Processing: ${progress.percent}% done`);
          })
          .on('end', () => {
            console.log('HLS streams created successfully');
            resolve();
          })
          .on('error', (err) => {
            console.error('Error during HLS transcoding:', err);
            reject(err);
          })
          .run();
      });

      // Generate preview video (keeping as fallback)
      console.log('Starting preview video transcoding...');
      await new Promise((resolve, reject) => {
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
            console.log(`Processing: ${progress.percent}% done`);
          })
          .on('end', () => {
            console.log('Preview video created successfully');
            resolve();
          })
          .on('error', (err) => {
            console.error('Error during transcoding:', err);
            reject(err);
          })
          .run();
      });
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

    // Determine the destination paths
    const pathParts = filePath.split('/');
    if (pathParts.length < 3) {
      console.error('Invalid file path structure:', filePath);
      // Clean up temporary files before returning
      try {
        fs.unlinkSync(tempFilePath);
        fs.unlinkSync(tempPreviewFilePath);
        fs.unlinkSync(tempThumbnailPath);
        fs.rmSync(tempHlsDir, { recursive: true, force: true });
      } catch (cleanupError) {
        console.error('Error during cleanup:', cleanupError);
      }
      return null;
    }

    // Extract userId from the path and define destinations
    const userId = pathParts[1];
    const previewDestination = `previews/${userId}/${previewFileName}`;
    const thumbnailDestination = `thumbnails/${userId}/${thumbnailFileName}`;
    const hlsDestinationBase = `hls/${userId}/${hlsBaseName}`;

    // Upload both the preview video and thumbnail
    console.log('Uploading preview video, thumbnail, and HLS streams...');
    try {
      // Get list of HLS files
      const hlsFiles = fs.readdirSync(tempHlsDir);
      
      // Upload all files
      await Promise.all([
        bucket.upload(tempPreviewFilePath, {
          destination: previewDestination,
          metadata: {
            contentType: 'video/mp4',
            metadata: { originalVideo: filePath }
          },
        }),
        bucket.upload(tempThumbnailPath, {
          destination: thumbnailDestination,
          metadata: {
            contentType: 'image/jpeg',
            metadata: { originalVideo: filePath }
          },
        }),
        // Upload all HLS files
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

      // Make all files publicly accessible
      await Promise.all([
        bucket.file(previewDestination).makePublic(),
        bucket.file(thumbnailDestination).makePublic(),
        ...hlsFiles.map(file => 
          bucket.file(`${hlsDestinationBase}/${file}`).makePublic()
        )
      ]);

      const previewUrl = `https://storage.googleapis.com/${fileBucket}/${previewDestination}`;
      const thumbnailUrl = `https://storage.googleapis.com/${fileBucket}/${thumbnailDestination}`;
      const hlsUrl = `https://storage.googleapis.com/${fileBucket}/${hlsDestinationBase}/playlist.m3u8`;
      console.log('Files are publicly available at:', { previewUrl, thumbnailUrl });
      console.log('HLS URL:', hlsUrl);

      // Update Firestore if postId is provided
      if (object.metadata && object.metadata.postId) {
        const postId = object.metadata.postId;
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
    } catch (uploadError) {
      console.error('Error during upload:', uploadError);
      // If upload fails, clean up the temporary files and return
      try {
        fs.unlinkSync(tempFilePath);
        fs.unlinkSync(tempPreviewFilePath);
        fs.unlinkSync(tempThumbnailPath);
        fs.rmSync(tempHlsDir, { recursive: true, force: true });
      } catch (cleanupError) {
        console.error('Error during cleanup after upload failure:', cleanupError);
      }
      return null;
    }

    // Clean up temporary files
    console.log('Cleaning up temporary files');
    try {
      fs.unlinkSync(tempFilePath);
      fs.unlinkSync(tempPreviewFilePath);
      fs.unlinkSync(tempThumbnailPath);
      fs.rmSync(tempHlsDir, { recursive: true, force: true });
    } catch (cleanupError) {
      console.error('Error during final cleanup:', cleanupError);
      // Don't throw since processing is complete
    }

    console.log('Processing complete');
    return null;
  });

// Cloud Function to send notifications to group members
exports.sendGroupNotifications = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    try {
      const notification = snap.data();
      const { tokens, title, body } = notification;

      if (!tokens || tokens.length === 0) {
        console.log('No tokens provided');
        return null;
      }

      const message = {
        notification: {
          title,
          body,
        },
        tokens: tokens,
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
      };

      // Send the messages
      const response = await admin.messaging().sendMulticast(message);

      console.log('Successfully sent messages:', response);
      return response;
    } catch (error) {
      console.error('Error sending notifications:', error);
      return null;
    }
  }); 