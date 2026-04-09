import { db } from '../db/index.js';
import { notificationPreferences, users, notificationTemplates } from '../db/schema.js';
import { eq, and } from 'drizzle-orm';
import { sendEmail } from './emailService.js';
import { sendWhatsAppCampaign } from './whatsappService.js';
/**
 * Helper to replace placeholders like {taskTitle} with actual data
 */
const replacePlaceholders = (template, data) => {
    if (!template) return '';
    return template.replace(/{([^{}]+)}/g, (match, key) => {
        const cleanKey = key.trim();
        const value = data[cleanKey];
        if (value !== undefined && value !== null && String(value).trim() !== '') {
            return value;
        }
        return '';
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
            emailNotifications: true,
            notificationChannels: {
                newTask: { admin: true, manager: true, member: true },
                newTaskInLoop: { admin: true, manager: true, member: true },
                taskEdit: { admin: true, manager: true, member: true },
                taskEditInLoop: { admin: true, manager: true, member: true },
                taskComment: { admin: true, manager: true, member: true },
                taskCommentInLoop: { admin: true, manager: true, member: true },
                taskInProgress: { admin: true, manager: true, member: true },
                taskInProgressInLoop: { admin: true, manager: true, member: true },
                taskComplete: { admin: true, manager: true, member: true },
                taskCompleteInLoop: { admin: true, manager: true, member: true },
                taskReOpen: { admin: true, manager: true, member: true },
                taskReOpenInLoop: { admin: true, manager: true, member: true }
            }
        };

        // Merge user prefs with defaults to prevent missing keys
        const currentPrefs = {
            ...defaultPrefs,
            ...(prefs || {}),
            notificationChannels: {
                ...defaultPrefs.notificationChannels,
                ...(prefs?.notificationChannels || {})
            }
        };

        // Fetch custom templates for this event
        const templates = await db.select()
            .from(notificationTemplates)
            .where(and(
                eq(notificationTemplates.eventName, eventType),
                eq(notificationTemplates.isActive, true)
            ));

        const getTemplate = (channel) => templates.find(t => t.channel === channel);

        // Special handling for reminders and daily reports
        if (eventType === 'reminder' || eventType === 'dailyPendingReminders' || eventType === 'reminderInLoop') {
            const promises = [];
            const emailTemplate = getTemplate('email');

            const rc = data.reminderChannel ? data.reminderChannel.toLowerCase() : null;
            let isEmailEnabled = (eventType === 'reminder' || eventType === 'reminderInLoop') ? currentPrefs.emailReminders : currentPrefs.emailNotifications;
            if (rc) isEmailEnabled = (rc === 'email' || rc === 'both');

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
            
            let isWhatsappEnabled = true; // By default trigger for all other events
            if (rc) isWhatsappEnabled = (rc === 'whatsapp' || rc === 'both');

            // Trigger WhatsApp Campaign unconditionally or based on clean setup
            if (isWhatsappEnabled && user.mobileNumber) {
                const cleanNumber = user.mobileNumber.replace(/\D/g, '');
                const whatsappTemplate = getTemplate('whatsapp');
                let campaignName = process.env.AISENSY_CAMPAIGN_NAME || 'RLD3';
                let templateParams = [];

                if (whatsappTemplate) {
                    campaignName = whatsappTemplate.subject?.trim() || campaignName;
                    const rawBody = replacePlaceholders(whatsappTemplate.body, data);
                    templateParams = rawBody.trim().split('\n').map(l => l.trim() || ' ');
                } else {
                    const campaignMapping = {
                        reminder: process.env.AISENSY_CAMPAIGN_REMINDER || 'task_reminder_update',
                        reminderInLoop: process.env.AISENSY_CAMPAIGN_REMINDER_INLOOP || 'task_reminder_inloop_update',
                        dailyPendingReminders: process.env.AISENSY_CAMPAIGN_DAILY || 'daily_pending_update'
                    };
                    campaignName = campaignMapping[eventType] || campaignName;
                    
                    templateParams = [
                        String(data.taskId || 'N/A'),
                        String(data.taskTitle || 'N/A'),
                        String(data.category || 'N/A'),
                        String(data.priority || 'N/A'),
                        String(data.status || 'Pending'),
                        String(data.assignerName || 'N/A'),
                        String(data.doerName || 'N/A'),
                        (data.taskDescription ? String(data.taskDescription).substring(0, 500) : 'No description provided')
                    ];
                }
                
                promises.push(sendWhatsAppCampaign(cleanNumber, user.firstName + ' ' + user.lastName, campaignName, templateParams));
            }
            
            await Promise.all(promises);
            return;
        }

        const userRole = (user.role || '').toLowerCase().replace(' ', '').replace('_', '');
        let mappedRole = 'member';
        if (userRole.includes('admin')) mappedRole = 'admin';
        if (userRole.includes('manager')) mappedRole = 'manager';

        const channelSettings = currentPrefs.notificationChannels ? currentPrefs.notificationChannels[eventType] : null;
        const isEnabledForRole = channelSettings && (channelSettings[mappedRole] || channelSettings.member);

        console.log(`[Notifier] Event: ${eventType}, User: ${user.firstName}, Role: ${mappedRole}, Enabled: ${!!isEnabledForRole}`);

        if (!isEnabledForRole) return;

        // 2. Send Notifications
        const promises = [];
        const emailTemplate = getTemplate('email');

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

        // Trigger WhatsApp Campaign
        if (user.mobileNumber) {
            const cleanNumber = user.mobileNumber.replace(/\D/g, '');
            const whatsappTemplate = getTemplate('whatsapp');
            let campaignName = process.env.AISENSY_CAMPAIGN_NAME || 'RLD3';
            let templateParams = [];

            if (whatsappTemplate) {
                campaignName = whatsappTemplate.subject?.trim() || campaignName;
                const rawBody = replacePlaceholders(whatsappTemplate.body, data);
                templateParams = rawBody.trim().split('\n').map(l => l.trim() || ' ');
            } else {
                const campaignMapping = {
                    newTask: process.env.AISENSY_CAMPAIGN_NEW_TASK || 'new_task_update',
                    newTaskInLoop: process.env.AISENSY_CAMPAIGN_NEW_TASK_INLOOP || 'new_task_inloop_update',
                    taskEdit: process.env.AISENSY_CAMPAIGN_TASK_EDIT || 'task_edit_update',
                    taskEditInLoop: process.env.AISENSY_CAMPAIGN_TASK_EDIT_INLOOP || 'task_edit_inloop_update',
                    taskComment: process.env.AISENSY_CAMPAIGN_TASK_COMMENT || 'task_comment_update',
                    taskCommentInLoop: process.env.AISENSY_CAMPAIGN_TASK_COMMENT_INLOOP || 'task_comment_inloop_update',
                    taskInProgress: process.env.AISENSY_CAMPAIGN_TASK_INPROGRESS || 'task_inprogress_update',
                    taskInProgressInLoop: process.env.AISENSY_CAMPAIGN_TASK_INPROGRESS_INLOOP || 'task_inprogress_inloop_update',
                    taskComplete: process.env.AISENSY_CAMPAIGN_TASK_COMPLETE || 'task_complete_update',
                    taskCompleteInLoop: process.env.AISENSY_CAMPAIGN_TASK_COMPLETE_INLOOP || 'task_complete_inloop_update',
                    taskReOpen: process.env.AISENSY_CAMPAIGN_TASK_REOPEN || 'task_reopen_update',
                    taskReOpenInLoop: process.env.AISENSY_CAMPAIGN_TASK_REOPEN_INLOOP || 'task_reopen_inloop_update'
                };
                campaignName = campaignMapping[eventType] || campaignName;
                
                templateParams = [
                    String(data.taskId || 'N/A'),
                    String(data.taskTitle || 'N/A'),
                    String(data.category || 'N/A'),
                    String(data.priority || 'N/A'),
                    String(data.status || 'Pending'),
                    String(data.assignerName || 'N/A'),
                    String(data.doerName || 'N/A'),
                    (data.taskDescription ? String(data.taskDescription).substring(0, 500) : 'No description provided')
                ];
            }
            
            promises.push(sendWhatsAppCampaign(cleanNumber, user.firstName + ' ' + user.lastName, campaignName, templateParams));
        }
        await Promise.all(promises);

    } catch (error) {
        console.error('Error in notifyUser orchestrator:', error);
    }
};
