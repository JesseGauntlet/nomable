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
  .object()
  .onFinalize(async (object) => {
    // Read file metadata from the event
    const fileBucket = object.bucket;
    const filePath = object.name;
    const contentType = object.contentType;

    // Only process video files that are uploaded to the /videos/ directory
    if (!filePath || !filePath.startsWith('videos/')) {
      console.log('This file is not uploaded to the /videos/ directory. Exiting function.');
      return null;
    }

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

    // Define an output file path for the preview video
    const previewFileName = fileName.replace('.mp4', '_preview.mp4');
    const tempPreviewFilePath = path.join(os.tmpdir(), previewFileName);

    // Transcode the video using ffmpeg to create a lower-resolution preview
    try {
      console.log('Starting video transcoding...');
      await new Promise((resolve, reject) => {
        ffmpeg(tempFilePath)
          // Set video filter to scale height to 480p and adjust width automatically
          .outputOptions([
            '-vf', 'scale=-2:480',
            '-c:a', 'copy',
            // Add additional compression settings
            '-c:v', 'libx264',
            '-crf', '28', // Compression quality (23-28 is a good range)
            '-preset', 'medium' // Encoding speed preset
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
    } catch (transcodingError) {
      console.error('Error in transcoding process:', transcodingError);
      // Clean up the downloaded original video
      fs.unlinkSync(tempFilePath);
      return null;
    }

    // Determine the destination path for the preview video
    // Example: videos/userId/video.mp4 -> previews/userId/video_preview.mp4
    const pathParts = filePath.split('/');
    if (pathParts.length < 3) {
      console.error('Invalid file path structure:', filePath);
      return null;
    }
    const userId = pathParts[1];
    const previewDestination = `previews/${userId}/${previewFileName}`;

    // Upload the preview video file to Cloud Storage
    console.log('Uploading preview video to:', previewDestination);
    await bucket.upload(tempPreviewFilePath, {
      destination: previewDestination,
      metadata: {
        contentType: 'video/mp4',
        // Include metadata to link this preview to the original video
        metadata: {
          originalVideo: filePath
        }
      },
    });

    // Make the preview video publicly accessible
    const previewFile = bucket.file(previewDestination);
    await previewFile.makePublic();
    const previewUrl = `https://storage.googleapis.com/${fileBucket}/${previewDestination}`;
    console.log('Preview video is publicly available at:', previewUrl);

    // If the original upload included a postId in metadata, update the Firestore document
    if (object.metadata && object.metadata.postId) {
      const postId = object.metadata.postId;
      console.log('Updating Firestore document:', postId);
      const postRef = admin.firestore().collection('posts').doc(postId);
      
      try {
        await postRef.update({
          previewUrl: previewUrl,
          previewGenerated: true,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log('Successfully updated Firestore document');
      } catch (error) {
        console.error('Error updating Firestore document:', error);
      }
    } else {
      console.log('No postId metadata found; skipping Firestore update');
    }

    // Clean up temporary files
    console.log('Cleaning up temporary files');
    fs.unlinkSync(tempFilePath);
    fs.unlinkSync(tempPreviewFilePath);

    console.log('Preview generation complete');
    return null;
  }); 