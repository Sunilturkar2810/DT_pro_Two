import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import dotenv from 'dotenv';

dotenv.config();

const s3Client = new S3Client({
    region: process.env.AWS_REGION,
    credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
    },
});

export const uploadToS3 = async (fileBuffer, fileName, folder = 'uploads') => {
    const key = `${folder}/${Date.now()}-${fileName}`;
    const command = new PutObjectCommand({
        Bucket: process.env.AWS_BUCKET_NAME,
        Key: key,
        Body: fileBuffer,
        // ContentType will be inferred if possible, but you can pass it if needed
    });

    await s3Client.send(command);

    // Return the public URL (assuming the bucket is configured for public read or you use CloudFront)
    // For this specific case, we'll construct the standard S3 URL
    return `https://${process.env.AWS_BUCKET_NAME}.s3.${process.env.AWS_REGION}.amazonaws.com/${key}`;
};
