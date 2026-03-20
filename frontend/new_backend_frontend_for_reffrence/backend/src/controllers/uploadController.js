import { uploadToS3 } from '../utils/s3.js';
import { db } from '../db/index.js';
import { users } from '../db/schema.js';
import { eq } from 'drizzle-orm';

export const uploadProfileImage = async (request, reply) => {
    const data = await request.file();
    
    if (!data) {
        return reply.code(400).send({ message: 'No file uploaded' });
    }

    // Basic MIME type check
    if (!data.mimetype.startsWith('image/')) {
        return reply.code(400).send({ message: 'Only image files are allowed' });
    }

    try {
        console.log('Starting upload for:', data.filename, 'Mime:', data.mimetype);
        const buffer = await data.toBuffer();
        const fileUrl = await uploadToS3(buffer, data.filename, 'profile-images', data.mimetype);
        console.log('Upload successful, URL:', fileUrl);
        
        // Optionally update user record immediately if userId is provided or from auth
        const userId = request.user?.id;
        console.log('Authenticated User ID:', userId);

        if (userId) {
            await db.update(users)
                .set({ profilePhotoUrl: fileUrl, updatedAt: new Date() })
                .where(eq(users.userId, userId));
            console.log('Database updated for user:', userId);
        }

        return reply.send({ 
            message: 'Image uploaded successfully', 
            url: fileUrl 
        });
    } catch (error) {
        console.error('SERVER UPLOAD ERROR:', error);
        request.log.error(error);
        return reply.code(500).send({ 
            message: 'Internal Server Error during upload',
            error: error.message,
            stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
        });
    }
};
