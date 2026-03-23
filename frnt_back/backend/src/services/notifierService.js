import { db } from '../db/index.js';
import { notificationPreferences, users, notificationTemplates } from '../db/schema.js';
import { eq, and } from 'drizzle-orm';
import { sendEmail } from './emailService.js';
import { sendWhatsAppMessage } from './whatsappService.js';

/**
 * Helper to replace placeholders like {taskTitle} with actual data
 */
const replacePlaceholders = (template, data) => {
    if (!template) return '';
    return template.replace(/{([\w]+)}/g, (match, key) => {
        return data[key] !== undefined ? data[key] : match;
    });
};


/**
 * Orchestrates sending notifications based on user preferences
 * @param {string} userId - ID of the user to notify
 * @param {string} eventType - Type of event (newTask, taskEdit, taskComment, taskInProgress, taskComplete, taskReOpen)
 * @param {object} data - Notification content { title, message, html, ...variables }
 */
export const notifyUser = async (userId, eventType, data) => {
    try {
        // 1. Fetch user and their preferences
        const [user] = await db.select().from(users).where(eq(users.userId, userId));
        if (!user) return;

        const [prefs] = await db.select().from(notificationPreferences).where(eq(notificationPreferences.userId, userId));
        
        const defaultPrefs = {
            whatsappNotifications: false,
            emailNotifications: true,
            notificationChannels: {
                newTask: { admin: true, manager: true, member: true },
                taskEdit: { admin: true, manager: true, member: true },
                taskComment: { admin: true, manager: true, member: true },
                taskInProgress: { admin: true, manager: true, member: true },
                taskComplete: { admin: true, manager: true, member: true },
                taskReOpen: { admin: true, manager: true, member: true }
            }
        };

        const currentPrefs = prefs || defaultPrefs;

        // Fetch custom templates for this event
        const templates = await db.select()
            .from(notificationTemplates)
            .where(and(
                eq(notificationTemplates.eventName, eventType),
                eq(notificationTemplates.isActive, true)
            ));

        const getTemplate = (channel) => templates.find(t => t.channel === channel);

        // Special handling for reminders and daily reports
        if (eventType === 'reminder' || eventType === 'dailyPendingReminders') {
            console.log(`[Notifier] Processing ${eventType} for user ${userId}`);
            const promises = [];
            const emailTemplate = getTemplate('email');
            const whatsappTemplate = getTemplate('whatsapp');

            let isEmailEnabled = (eventType === 'reminder' || eventType === 'dailyPendingReminders') ? currentPrefs.emailReminders : currentPrefs.emailNotifications;
            let isWhatsappEnabled = (eventType === 'reminder' || eventType === 'dailyPendingReminders') ? currentPrefs.whatsappReminders : currentPrefs.whatsappNotifications;

            // Override if specific channel is requested in data.type
            if (data.type) {
                if (data.type === 'email') { isEmailEnabled = true; isWhatsappEnabled = false; }
                else if (data.type === 'whatsapp') { isEmailEnabled = false; isWhatsappEnabled = true; }
                else if (data.type === 'both') { isEmailEnabled = true; isWhatsappEnabled = true; }
            }

            console.log(`[Notifier] Channels enabled - Email: ${isEmailEnabled}, WhatsApp: ${isWhatsappEnabled}`);

            if (isEmailEnabled && user.workEmail) {
                let subject = data.title;
                let content = data.html || data.message;
                if (emailTemplate) {
                    subject = replacePlaceholders(emailTemplate.subject || data.title, data);
                    content = replacePlaceholders(emailTemplate.body, data);
                    console.log(`[Notifier] Using custom email template for ${eventType}`);
                }
                console.log(`[Notifier] Sending email to ${user.workEmail}`);
                promises.push(sendEmail(user.workEmail, subject, content, data.attachments || []));
            }
            if (isWhatsappEnabled && user.mobileNumber) {
                let content = data.message;
                if (whatsappTemplate) {
                    content = replacePlaceholders(whatsappTemplate.body, data);
                    console.log(`[Notifier] Using custom WhatsApp template for ${eventType}`);
                }
                const cleanNumber = user.mobileNumber.replace(/\D/g, ''); 
                console.log(`[Notifier] Sending WhatsApp to ${cleanNumber}`);
                promises.push(sendWhatsAppMessage(cleanNumber, content));
            }
            const results = await Promise.all(promises);
            console.log(`[Notifier] Completed ${eventType} notifications for ${userId}. Sent: ${results.length}`);
            return;
        }

        const userRole = user.role.toLowerCase().replace(' ', '').replace('_', '');
        let mappedRole = 'member';
        if (userRole.includes('admin')) mappedRole = 'admin';
        if (userRole.includes('manager')) mappedRole = 'manager';

        const channelSettings = currentPrefs.notificationChannels ? currentPrefs.notificationChannels[eventType] : null;
        const isEnabledForRole = channelSettings && (channelSettings[mappedRole] || channelSettings.member); // Fallback to member if role not specifically found

        if (!isEnabledForRole) return;

        // 2. Send Notifications
        const promises = [];
        const emailTemplate = getTemplate('email');
        const whatsappTemplate = getTemplate('whatsapp');

        // Email
        if (currentPrefs.emailNotifications && user.workEmail) {
            let subject = data.title;
            let content = data.html || data.message;
            if (emailTemplate) {
                subject = replacePlaceholders(emailTemplate.subject || data.title, data);
                content = replacePlaceholders(emailTemplate.body, data);
            }
            promises.push(sendEmail(user.workEmail, subject, content, data.attachments || []));
        }

        // WhatsApp
        if (currentPrefs.whatsappNotifications && user.mobileNumber) {
            let content = data.message;
            if (whatsappTemplate) {
                content = replacePlaceholders(whatsappTemplate.body, data);
            }
            const cleanNumber = user.mobileNumber.replace(/\D/g, ''); 
            promises.push(sendWhatsAppMessage(cleanNumber, content));
        }

        await Promise.all(promises);

    } catch (error) {
        console.error('Error in notifyUser orchestrator:', error);
    }
};
