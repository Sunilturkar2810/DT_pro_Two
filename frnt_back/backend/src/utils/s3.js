import { S3Client, PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import dotenv from 'dotenv';

dotenv.config();

const s3Client = new S3Client({
    region: process.env.AWS_REGION,
    credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
    },
});

/**
 * Upload a file to S3 and return a public-style URL
 * Note: This URL might not be accessible if the bucket is private.
 * Use getPresignedUrl for temporary authenticated access.
 */
export const uploadToS3 = async (fileBody, fileName, folder = 'uploads', contentType = null) => {
    const key = `${folder}/${Date.now()}-${fileName}`;
    const params = {
        Bucket: process.env.AWS_BUCKET_NAME,
        Key: key,
        Body: fileBody,
    };

    if (contentType) {
        params.ContentType = contentType;
    }

    const command = new PutObjectCommand(params);
    await s3Client.send(command);

    return `https://${process.env.AWS_BUCKET_NAME}.s3.${process.env.AWS_REGION}.amazonaws.com/${key}`;
};

/**
 * Generate a pre-signed URL for a given S3 key or full S3 URL
 */
export const getPresignedUrl = async (keyOrUrl, expiresIn = 604800) => { // Default to 7 days
    if (!keyOrUrl) return keyOrUrl;
    
    try {
        let key = keyOrUrl;
        
        // If it's a full URL, extract the key
        if (keyOrUrl.startsWith('http')) {
            const urlParts = keyOrUrl.split('.com/');
            if (urlParts.length > 1) {
                key = urlParts[1];
            } else {
                // Not an S3 URL we recognize, return as is
                return keyOrUrl;
            }
        }

        const command = new GetObjectCommand({
            Bucket: process.env.AWS_BUCKET_NAME,
            Key: key,
        });

        // Generate the pre-signed URL
        const signedUrl = await getSignedUrl(s3Client, command, { expiresIn });
        return signedUrl;
    } catch (error) {
        console.error('Error generating pre-signed URL:', error.message);
        return keyOrUrl; // Fallback to original
    }
};

/**
 * Recursively find and sign S3 URLs in an object or array
 */
export const signAllS3Urls = async (data) => {
    if (!data || typeof data !== 'object') return data;

    const signValue = async (val) => {
        if (typeof val === 'string' && val.includes('.s3.') && val.includes('amazonaws.com')) {
            return await getPresignedUrl(val);
        }
        if (Array.isArray(val)) {
            return await Promise.all(val.map(item => signValue(item)));
        }
        if (val && typeof val === 'object' && !(val instanceof Date)) {
            const newVal = {};
            for (const key of Object.keys(val)) {
                newVal[key] = await signValue(val[key]);
            }
            return newVal;
        }
        return val;
    };

    return await signValue(data);
};

export const getS3File = async (key) => {
    try {
        const command = new GetObjectCommand({
            Bucket: process.env.AWS_BUCKET_NAME,
            Key: key,
        });

        const response = await s3Client.send(command);
        const chunks = [];
        for await (const chunk of response.Body) {
            chunks.push(chunk);
        }
        return Buffer.concat(chunks);
    } catch (error) {
        console.error(`Error fetching from S3 (${key}):`, error.message);
        throw error;
    }
};

