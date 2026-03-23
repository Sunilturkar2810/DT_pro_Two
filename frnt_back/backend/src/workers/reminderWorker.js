import cron from 'node-cron';
import { db } from '../db/index.js';
import { taskReminders, delegations, users } from '../db/schema.js';
import { eq, and, lte } from 'drizzle-orm';
import { notifyUser } from '../services/notifierService.js';

export const initReminderWorker = () => {
    // Run every minute
    cron.schedule('* * * * *', async () => {
        console.log('[ReminderWorker] Checking for due reminders...');
        
        try {
            const now = new Date();
            
            // Find unsent reminders where reminderTime <= now
            const pendingReminders = await db.select({
                reminder: taskReminders,
                delegation: delegations,
                doer: users
            })
            .from(taskReminders)
            .innerJoin(delegations, eq(taskReminders.delegationId, delegations.id))
            .innerJoin(users, eq(delegations.doerId, users.userId))
            .where(
                and(
                    eq(taskReminders.isSent, false),
                    lte(taskReminders.reminderTime, now)
                )
            );

            if (pendingReminders.length === 0) {
                return;
            }

            console.log(`[ReminderWorker] Found ${pendingReminders.length} pending reminders.`);

            for (const item of pendingReminders) {
                const { reminder, delegation, doer } = item;

                try {
                    const eventType = 'reminder'; // We can map this to 'newTask' or custom if needed
                    const message = `Reminder: Your task "${delegation.taskTitle}" is due ${reminder.triggerType} ${reminder.timeValue} ${reminder.timeUnit}.`;
                    
                    await notifyUser(doer.userId, 'reminder', { 
                        type: reminder.type,
                        title: 'Task Reminder',
                        message,
                        html: `
                            <div style="font-family: sans-serif; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
                                <h2 style="color: #10b981;">Task Reminder</h2>
                                <p><strong>Task:</strong> ${delegation.taskTitle}</p>
                                <p>${message}</p>
                                <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
                                <p style="font-size: 12px; color: #6b7280;">Please log in to the portal to view more details.</p>
                            </div>
                        `,
                        // Variables for templates
                        taskTitle: delegation.taskTitle,
                        description: delegation.description,
                        priority: delegation.priority,
                        category: delegation.category,
                        dueDate: delegation.dueDate ? new Date(delegation.dueDate).toLocaleDateString() : 'No due date',
                        status: delegation.status,
                        reminderTrigger: reminder.triggerType,
                        reminderValue: `${reminder.timeValue} ${reminder.timeUnit}`,
                        // Additional variables requested
                        voiceNoteUrl: delegation.voiceNoteUrl || 'None',
                        referenceDocs: delegation.referenceDocs || 'None',
                        tags: Array.isArray(delegation.tags) ? delegation.tags.map(t => typeof t === 'object' ? t.text : t).join(', ') : 'None',
                        checklistItems: (delegation.checklistItems && delegation.checklistItems.length > 0) 
                            ? delegation.checklistItems.map(item => `• ${item.text || item.itemName || 'Checklist Item'}`).join('\n')
                            : 'No checklist items',
                        evidenceRequired: delegation.evidenceRequired === true ? 'Yes' : 'No',
                        evidenceUrl: delegation.evidenceUrl || 'None',
                        revisionCount: delegation.revisionCount || 0,
                        inLoopIds: Array.isArray(delegation.inLoopIds) ? delegation.inLoopIds.join(', ') : 'None',
                        frequency: (delegation.frequency || 'Once'),
                        fromDate: delegation.createdAt ? new Date(delegation.createdAt).toLocaleDateString() : 'N/A'
                    });

                    // Mark as sent
                    await db.update(taskReminders)
                        .set({ isSent: true, updatedAt: new Date() })
                        .where(eq(taskReminders.id, reminder.id));
                    
                    console.log(`[ReminderWorker] Sent reminder ${reminder.id} for task ${delegation.id}`);
                } catch (sendError) {
                    console.error(`[ReminderWorker] Failed to send reminder ${reminder.id}:`, sendError);
                }
            }
        } catch (error) {
            console.error('[ReminderWorker] Error in reminder worker loop:', error);
        }
    });
    
    console.log('[ReminderWorker] Initialized successfully.');
};
