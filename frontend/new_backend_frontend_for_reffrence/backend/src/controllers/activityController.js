import { db } from '../db/index.js';
import { activities, users } from '../db/schema.js';
import { desc, eq, and, gte, lte, ilike, or } from 'drizzle-orm';

export const getActivities = async (req, reply) => {
    try {
        const { userId, startDate, endDate, search, limit = 100 } = req.query;
        let conditions = [];

        if (userId && userId !== 'Updated By') {
            conditions.push(eq(activities.userId, userId));
        }

        if (startDate) {
            conditions.push(gte(activities.createdAt, new Date(startDate)));
        }

        if (endDate) {
            conditions.push(lte(activities.createdAt, new Date(endDate)));
        }

        if (search) {
            conditions.push(or(
                ilike(activities.title, `%${search}%`),
                ilike(activities.description, `%${search}%`)
            ));
        }

        const queryResult = await db.select({
            id: activities.id,
            type: activities.type,
            title: activities.title,
            description: activities.description,
            userId: activities.userId,
            relatedId: activities.relatedId,
            relatedType: activities.relatedType,
            metadata: activities.metadata,
            createdAt: activities.createdAt,
            user: {
                userId: users.userId,
                firstName: users.firstName,
                lastName: users.lastName,
                designation: users.designation,
                profilePhotoUrl: users.profilePhotoUrl
            }
        })
        .from(activities)
        .leftJoin(users, eq(activities.userId, users.userId))
        .where(conditions.length > 0 ? and(...conditions) : undefined)
        .orderBy(desc(activities.createdAt))
        .limit(parseInt(limit));

        return reply.status(200).send({
            success: true,
            data: queryResult
        });

    } catch (error) {
        req.log.error(error);
        return reply.status(500).send({
            success: false,
            message: 'Failed to fetch activities',
            error: error.message
        });
    }
};
