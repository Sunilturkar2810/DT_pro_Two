import { db } from '../db/index.js';
import { activities } from '../db/schema.js';

export const logActivity = async ({ type, title, description, userId, relatedId, relatedType, metadata }) => {
    try {
        await db.insert(activities).values({
            type,
            title,
            description,
            userId,
            relatedId,
            relatedType,
            metadata: metadata || {}
        });
        return true;
    } catch (error) {
        console.error('Error logging activity:', error);
        return false;
    }
};
