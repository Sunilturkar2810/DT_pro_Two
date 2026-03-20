import { db } from '../db/index.js';
import { notificationPreferences } from '../db/schema.js';
import { eq } from 'drizzle-orm';

export const getNotificationSettings = async (req, reply) => {
    try {
        const userId = req.user.id;
        
        let settings = await db.select()
            .from(notificationPreferences)
            .where(eq(notificationPreferences.userId, userId))
            .limit(1);

        if (settings.length === 0) {
            // Return defaults if no settings found
            return reply.status(200).send({
                success: true,
                data: {
                    whatsappNotifications: false,
                    emailNotifications: false,
                    timezone: 'Asia/Kolkata',
                    dailyReminderTime: '09:00',
                    whatsappReminders: false,
                    emailReminders: false,
                    dailyTaskReport: false,
                    weeklyOffs: ['Sunday'],
                    notificationChannels: {
                        newTask: { admin: true, manager: true, member: true },
                        taskEdit: { admin: true, manager: true, member: true },
                        taskComment: { admin: true, manager: true, member: true },
                        taskInProgress: { admin: true, manager: true, member: true },
                        taskComplete: { admin: true, manager: true, member: true },
                        taskReOpen: { admin: true, manager: true, member: true }
                    },
                    notificationFrequency: {
                        admin: {
                            newTask: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
                            taskEdit: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
                            taskComment: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
                            taskInProgress: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
                            taskComplete: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
                            taskReOpen: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
                            dailyPendingReminders: { once: true, daily: false, weekly: false, monthly: false, yearly: false }
                        },
                        manager: {
                            newTask: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
                            taskEdit: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
                            taskComment: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
                            taskInProgress: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
                            taskComplete: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
                            taskReOpen: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
                            dailyPendingReminders: { once: true, daily: false, weekly: false, monthly: false, yearly: false }
                        },
                        member: {
                            newTask: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
                            taskEdit: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
                            taskComment: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
                            taskInProgress: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
                            taskComplete: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
                            taskReOpen: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
                            dailyPendingReminders: { once: true, daily: false, weekly: false, monthly: false, yearly: false }
                        }
                    }
                }
            });
        }

        return reply.status(200).send({
            success: true,
            data: settings[0]
        });
    } catch (error) {
        req.log.error(error);
        return reply.status(500).send({
            success: false,
            message: 'Failed to fetch notification settings'
        });
    }
};

export const updateNotificationSettings = async (req, reply) => {
    try {
        const userId = req.user.id;
        const updates = req.body;

        // Ensure we don't overwrite userId
        delete updates.userId;
        delete updates.id;
        delete updates.createdAt;
        delete updates.updatedAt;

        const existing = await db.select()
            .from(notificationPreferences)
            .where(eq(notificationPreferences.userId, userId))
            .limit(1);

        if (existing.length > 0) {
            await db.update(notificationPreferences)
                .set({ ...updates, updatedAt: new Date() })
                .where(eq(notificationPreferences.userId, userId));
        } else {
            await db.insert(notificationPreferences)
                .values({ 
                    userId, 
                    ...updates,
                    updatedAt: new Date() 
                });
        }

        return reply.status(200).send({
            success: true,
            message: 'Notification settings updated successfully'
        });
    } catch (error) {
        req.log.error(error);
        return reply.status(500).send({
            success: false,
            message: 'Failed to update notification settings'
        });
    }
};
