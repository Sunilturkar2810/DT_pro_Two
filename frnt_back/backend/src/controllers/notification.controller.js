import { db } from '../db/index.js';
import { notifications } from '../db/schema.js';
import { eq, and, desc } from 'drizzle-orm';

export const createNotification = async (recipientId, title, message, type, relatedId = null) => {
    try {
        await db.insert(notifications).values({
            recipientId,
            title,
            message,
            type,
            relatedId
        });
        return true;
    } catch (error) {
        console.error('Error creating notification:', error);
        return false;
    }
};

export const getNotifications = async (req, reply) => {
    try {
        const userId = req.user.id;
        const userNotifications = await db.select()
            .from(notifications)
            .where(eq(notifications.recipientId, userId))
            .orderBy(desc(notifications.createdAt));

        return reply.status(200).send({
            success: true,
            data: userNotifications
        });
    } catch (error) {
        req.log.error(error);
        return reply.status(500).send({
            success: false,
            message: 'Failed to fetch notifications'
        });
    }
};

export const markAsRead = async (req, reply) => {
    try {
        const { id } = req.params;
        const userId = req.user.id;

        await db.update(notifications)
            .set({ isRead: true, updatedAt: new Date() })
            .where(and(
                eq(notifications.id, id),
                eq(notifications.recipientId, userId)
            ));

        return reply.status(200).send({
            success: true,
            message: 'Notification marked as read'
        });
    } catch (error) {
        req.log.error(error);
        return reply.status(500).send({
            success: false,
            message: 'Failed to mark notification as read'
        });
    }
};

export const markAllAsRead = async (req, reply) => {
    try {
        const userId = req.user.id;

        await db.update(notifications)
            .set({ isRead: true, updatedAt: new Date() })
            .where(eq(notifications.recipientId, userId));

        return reply.status(200).send({
            success: true,
            message: 'All notifications marked as read'
        });
    } catch (error) {
        req.log.error(error);
        return reply.status(500).send({
            success: false,
            message: 'Failed to mark all as read'
        });
    }
};

export const deleteNotification = async (req, reply) => {
    try {
        const { id } = req.params;
        const userId = req.user.id;

        await db.delete(notifications)
            .where(and(
                eq(notifications.id, id),
                eq(notifications.recipientId, userId)
            ));

        return reply.status(200).send({
            success: true,
            message: 'Notification deleted'
        });
    } catch (error) {
        req.log.error(error);
        return reply.status(500).send({
            success: false,
            message: 'Failed to delete notification'
        });
    }
};

export const clearAll = async (req, reply) => {
    try {
        const userId = req.user.id;

        await db.delete(notifications)
            .where(eq(notifications.recipientId, userId));

        return reply.status(200).send({
            success: true,
            message: 'All notifications cleared'
        });
    } catch (error) {
        req.log.error(error);
        return reply.status(500).send({
            success: false,
            message: 'Failed to clear notifications'
        });
    }
};
