const { S3Client, PutObjectCommand, DeleteObjectCommand } = require('@aws-sdk/client-s3');
const sharp = require('sharp');

// Initialize S3 client
const s3Client = new S3Client({
  region: process.env.AWS_REGION || 'us-east-1',
  credentials: process.env.AWS_ACCESS_KEY_ID ? {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
  } : undefined // Use IAM role if no credentials provided
});

const BUCKET_NAME = process.env.S3_AVATAR_BUCKET || 'kahoot-clone-user-avatars-802346121373';

/**
 * Upload avatar to S3
 * @param {Buffer} fileBuffer - Image file buffer
 * @param {String} userId - User ID
 * @param {String} originalName - Original filename
 * @returns {Promise<String>} - S3 URL of uploaded avatar
 */
async function uploadAvatar(fileBuffer, userId, originalName) {
  try {
    // Process image: resize and optimize
    const processedBuffer = await sharp(fileBuffer)
      .resize(400, 400, {
        fit: 'cover',
        position: 'center'
      })
      .jpeg({ quality: 85, progressive: true })
      .toBuffer();

    // Generate unique filename
    const timestamp = Date.now();
    const key = `avatars/${userId}-${timestamp}.jpg`;

    // Upload to S3
    const command = new PutObjectCommand({
      Bucket: BUCKET_NAME,
      Key: key,
      Body: processedBuffer,
      ContentType: 'image/jpeg',
      CacheControl: 'max-age=31536000', // 1 year
    });

    await s3Client.send(command);

    // Return public URL
    const avatarUrl = `https://${BUCKET_NAME}.s3.${process.env.AWS_REGION || 'us-east-1'}.amazonaws.com/${key}`;
    
    console.log('[S3] Avatar uploaded successfully:', avatarUrl);
    return avatarUrl;
  } catch (error) {
    console.error('[S3] Error uploading avatar:', error);
    throw new Error('Failed to upload avatar to S3');
  }
}

/**
 * Delete avatar from S3
 * @param {String} avatarUrl - Full S3 URL of avatar
 * @returns {Promise<void>}
 */
async function deleteAvatar(avatarUrl) {
  try {
    if (!avatarUrl || !avatarUrl.includes(BUCKET_NAME)) {
      console.log('[S3] No valid avatar URL to delete');
      return;
    }

    // Extract key from URL
    const urlParts = avatarUrl.split('.amazonaws.com/');
    if (urlParts.length < 2) {
      console.warn('[S3] Invalid S3 URL format:', avatarUrl);
      return;
    }
    
    const key = urlParts[1];

    // Delete from S3
    const command = new DeleteObjectCommand({
      Bucket: BUCKET_NAME,
      Key: key,
    });

    await s3Client.send(command);
    console.log('[S3] Avatar deleted successfully:', key);
  } catch (error) {
    // Don't throw error - just log it (avatar might already be deleted)
    console.error('[S3] Error deleting avatar:', error.message);
  }
}

/**
 * Replace avatar (delete old, upload new)
 * @param {Buffer} newFileBuffer - New image file buffer
 * @param {String} userId - User ID
 * @param {String} oldAvatarUrl - Old avatar URL to delete
 * @param {String} originalName - Original filename
 * @returns {Promise<String>} - S3 URL of new avatar
 */
async function replaceAvatar(newFileBuffer, userId, oldAvatarUrl, originalName) {
  try {
    // Delete old avatar if exists
    if (oldAvatarUrl) {
      await deleteAvatar(oldAvatarUrl);
    }

    // Upload new avatar
    const newAvatarUrl = await uploadAvatar(newFileBuffer, userId, originalName);
    
    return newAvatarUrl;
  } catch (error) {
    console.error('[S3] Error replacing avatar:', error);
    throw new Error('Failed to replace avatar');
  }
}

module.exports = {
  uploadAvatar,
  deleteAvatar,
  replaceAvatar
};
