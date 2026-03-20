import nodemailer from 'nodemailer';
import dotenv from 'dotenv';
import axios from 'axios';
import { getS3File } from '../utils/s3.js';

dotenv.config();

const transporter = nodemailer.createTransport({
    host: process.env.SMTP_SERVER,
    port: parseInt(process.env.SMTP_PORT || '587'),
    secure: process.env.SMTP_PORT === '465', // true for 465, false for other ports
    auth: {
        user: process.env.SMTP_USERNAME,
        pass: process.env.SMTP_PASSWORD,
    },
});

/**
 * Send an email notification
 * @param {string} to - Recipient email
 * @param {string} subject - Email subject
 * @param {string} html - HTML body
 * @param {Array} attachments - Optional attachments array [{filename, path/content}]
 */
export const sendEmail = async (to, subject, html, attachments = []) => {
    try {
        const bucketName = process.env.AWS_BUCKET_NAME;

        // Process attachments: fetch remote files if necessary
        const processedAttachments = await Promise.all((attachments || []).map(async (att) => {
            if (att.path && att.path.startsWith('http')) {
                try {
                    // Check if it's our S3 bucket
                    const s3Match = att.path.includes(`${bucketName}.s3`);
                    
                    if (s3Match) {
                        const urlParts = att.path.split('.com/');
                        if (urlParts.length > 1) {
                            const key = urlParts[1];
                            console.log(`Fetching from S3 via SDK: ${key}`);
                            const buffer = await getS3File(key);
                            return {
                                filename: att.filename,
                                content: buffer
                            };
                        }
                    }

                    // Fallback to axios for other URLs or if key extraction failed
                    console.log(`Fetching remote attachment via Axios: ${att.path}`);
                    const response = await axios.get(att.path, { 
                        responseType: 'arraybuffer',
                        timeout: 10000,
                        headers: { 'User-Agent': 'Mozilla/5.0' }
                    });
                    return {
                        filename: att.filename,
                        content: Buffer.from(response.data)
                    };
                } catch (fetchError) {
                    console.error(`Failed to fetch attachment from ${att.path}:`, fetchError.message);
                    return null; // Skip this attachment if it fails
                }
            }
            return att;
        }));

        const cleanAttachments = processedAttachments.filter(Boolean);

        const info = await transporter.sendMail({
            from: `"Kesariya Group" <${process.env.SMTP_USERNAME}>`,
            to,
            subject,
            html,
            attachments: cleanAttachments,
        });
        console.log('Email sent: %s', info.messageId);
        return info;
    } catch (error) {
        console.error('Error sending email:', error);
        throw error;
    }
};
