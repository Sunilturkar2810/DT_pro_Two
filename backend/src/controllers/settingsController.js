import { db } from '../db/index.js';
import { userSettings, taskUpdateSettings, notificationSettings } from '../db/schema.js';
import { eq } from 'drizzle-orm';

// General Settings
export const getGeneralSettings = async (request, reply) => {
    try {
        const userId = request.user.id;
        const settings = await db.query.userSettings.findFirst({
            where: eq(userSettings.userId, userId)
        });

        if (!settings) {
            return {
                companyName: '',
                businessIndustry: '',
                companySize: ''
            };
        }

        return settings;
    } catch (error) {
        reply.status(500).send({ error: error.message });
    }
};

export const updateGeneralSettings = async (request, reply) => {
    try {
        const userId = request.user.id;
        const { companyName, businessIndustry, companySize } = request.body;

        // Check if settings exist
        const existing = await db.query.userSettings.findFirst({
            where: eq(userSettings.userId, userId)
        });

        let result;
        if (existing) {
            result = await db.update(userSettings)
                .set({
                    companyName,
                    businessIndustry,
                    companySize,
                    updatedAt: new Date()
                })
                .where(eq(userSettings.userId, userId))
                .returning();
        } else {
            result = await db.insert(userSettings)
                .values({
                    userId,
                    companyName,
                    businessIndustry,
                    companySize,
                    createdAt: new Date(),
                    updatedAt: new Date()
                })
                .returning();
        }

        return {
            message: 'Settings updated successfully',
            data: result[0]
        };
    } catch (error) {
        reply.status(500).send({ error: error.message });
    }
};

// Task Update Settings
export const getTaskUpdateSettings = async (request, reply) => {
    try {
        const userId = request.user.id;
        const settings = await db.query.taskUpdateSettings.findFirst({
            where: eq(taskUpdateSettings.userId, userId)
        });

        if (!settings) {
            return {
                remarksRequired: true,
                attachmentsRequired: false,
                imagesRequired: false
            };
        }

        return settings;
    } catch (error) {
        reply.status(500).send({ error: error.message });
    }
};

export const updateTaskUpdateSettings = async (request, reply) => {
    try {
        const userId = request.user.id;
        const { remarksRequired, attachmentsRequired, imagesRequired } = request.body;

        // Check if settings exist
        const existing = await db.query.taskUpdateSettings.findFirst({
            where: eq(taskUpdateSettings.userId, userId)
        });

        let result;
        if (existing) {
            result = await db.update(taskUpdateSettings)
                .set({
                    remarksRequired,
                    attachmentsRequired,
                    imagesRequired,
                    updatedAt: new Date()
                })
                .where(eq(taskUpdateSettings.userId, userId))
                .returning();
        } else {
            result = await db.insert(taskUpdateSettings)
                .values({
                    userId,
                    remarksRequired,
                    attachmentsRequired,
                    imagesRequired,
                    createdAt: new Date(),
                    updatedAt: new Date()
                })
                .returning();
        }

        return {
            message: 'Task update settings saved successfully',
            data: result[0]
        };
    } catch (error) {
        reply.status(500).send({ error: error.message });
    }
};

// Notification Settings
export const getNotificationSettings = async (request, reply) => {
    try {
        const userId = request.user.id;
        const settings = await db.query.notificationSettings.findFirst({
            where: eq(notificationSettings.userId, userId)
        });

        if (!settings) {
            return {
                informaticsNotifications: true,
                emailNotifications: true,
                dailyReminder: true,
                emailReminders: true,
                taskReminderTime: '09:00',
                weeklyOnly: false,
                reminderDays: [],
                notificationChannels: {},
                notificationFrequency: {}
            };
        }

        return settings;
    } catch (error) {
        reply.status(500).send({ error: error.message });
    }
};

export const updateNotificationSettings = async (request, reply) => {
    try {
        const userId = request.user.id;
        const {
            informaticsNotifications,
            emailNotifications,
            dailyReminder,
            emailReminders,
            taskReminderTime,
            weeklyOnly,
            reminderDays,
            notificationChannels,
            notificationFrequency
        } = request.body;

        // Check if settings exist
        const existing = await db.query.notificationSettings.findFirst({
            where: eq(notificationSettings.userId, userId)
        });

        let result;
        if (existing) {
            result = await db.update(notificationSettings)
                .set({
                    informaticsNotifications,
                    emailNotifications,
                    dailyReminder,
                    emailReminders,
                    taskReminderTime,
                    weeklyOnly,
                    reminderDays,
                    notificationChannels,
                    notificationFrequency,
                    updatedAt: new Date()
                })
                .where(eq(notificationSettings.userId, userId))
                .returning();
        } else {
            result = await db.insert(notificationSettings)
                .values({
                    userId,
                    informaticsNotifications,
                    emailNotifications,
                    dailyReminder,
                    emailReminders,
                    taskReminderTime,
                    weeklyOnly,
                    reminderDays,
                    notificationChannels,
                    notificationFrequency,
                    createdAt: new Date(),
                    updatedAt: new Date()
                })
                .returning();
        }

        return {
            message: 'Notification settings updated successfully',
            data: result[0]
        };
    } catch (error) {
        reply.status(500).send({ error: error.message });
    }
};
