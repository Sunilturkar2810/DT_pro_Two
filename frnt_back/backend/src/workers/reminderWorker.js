import cron from 'node-cron';
import { db } from '../db/index.js';
import { taskReminders, delegations, users } from '../db/schema.js';
import { eq, and, lte, ne, gte } from 'drizzle-orm';
import { notifyUser } from '../services/notifierService.js';

const assignerAlias = users; // we'll do a sub-query approach

export const initReminderWorker = () => {
    // Run every minute
    cron.schedule('* * * * *', async () => {
        console.log('[ReminderWorker] Checking for due reminders...');
        
        try {
            const now = new Date();
            
            // Find unsent reminders where reminderTime <= now
            // AND the task is NOT completed
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
                    lte(taskReminders.reminderTime, now),
                    ne(delegations.status, 'Completed'),
                    gte(delegations.dueDate, now) // Stop reminders after end date
                )
            );

            // For each reminder, separately fetch assigner info
            if (pendingReminders.length === 0) {
                return;
            }

            console.log(`[ReminderWorker] Found ${pendingReminders.length} pending reminders.`);

            const reminderItems = await Promise.all(pendingReminders.map(async (item) => {
                const [assignerUser] = await db.select().from(users).where(eq(users.userId, item.delegation.assignerId));
                return { ...item, assigner: assignerUser || null };
            }));

            for (const item of reminderItems) {
                const { reminder, delegation, doer, assigner } = item;

                try {
                    const message = `Reminder: Task "${delegation.taskTitle}" is due ${reminder.triggerType} ${reminder.timeValue} ${reminder.timeUnit}.`;
                    
                    // 1. Notify Doer
                    await notifyUser(doer.userId, 'reminder', {
                        reminderChannel: reminder.type,
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
                        taskDescription: delegation.description,
                        priority: delegation.priority,
                        category: delegation.category,
                        dueDate: delegation.dueDate ? new Date(delegation.dueDate).toLocaleDateString('en-GB') : 'No due date',
                        status: delegation.status,
                        reminderTrigger: reminder.triggerType,
                        reminderValue: `${reminder.timeValue} ${reminder.timeUnit}`,
                        taskId: delegation.id,
                        doerName: `${doer.firstName} ${doer.lastName}`,
                        assignerName: assigner ? `${assigner.firstName} ${assigner.lastName}` : 'N/A',
                        voiceNoteUrl: delegation.voiceNoteUrl || 'No audio note',
                        referenceDocs: Array.isArray(delegation.referenceDocs) ? delegation.referenceDocs.join(', ') : (delegation.referenceDocs || 'No reference documents'),
                        evidenceUrl: delegation.evidenceUrl || 'No evidence provided'
                    });

                    // 2. Notify In-Loop Members
                    if (delegation.inLoopIds && Array.isArray(delegation.inLoopIds)) {
                        for (const loopMemberId of delegation.inLoopIds) {
                            if (!loopMemberId || loopMemberId === doer.userId || (assigner && loopMemberId === assigner.userId)) continue;
                            
                            // Get loop member details (could be optimized with a cache)
                            const [loopMember] = await db.select().from(users).where(eq(users.userId, loopMemberId));
                            if (!loopMember) continue;

                            await notifyUser(loopMemberId, 'reminderInLoop', {
                                reminderChannel: reminder.type,
                                title: '[In Loop] Task Reminder',
                                message: `Task Reminder: "${delegation.taskTitle}" is due ${reminder.triggerType} ${reminder.timeValue} ${reminder.timeUnit}. Assigned to: ${doer.firstName} ${doer.lastName}`,
                                html: `
                                    <div style="font-family: sans-serif; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
                                        <h2 style="color: #6366f1;">[In Loop] Task Reminder</h2>
                                        <p><strong>Task:</strong> ${delegation.taskTitle}</p>
                                        <p><strong>Assigned To:</strong> ${doer.firstName} ${doer.lastName}</p>
                                        <p>${message}</p>
                                    </div>
                                `,
                                taskTitle: delegation.taskTitle,
                                taskDescription: delegation.description,
                                priority: delegation.priority,
                                category: delegation.category,
                                dueDate: delegation.dueDate ? new Date(delegation.dueDate).toLocaleDateString('en-GB') : 'No due date',
                                status: delegation.status,
                                reminderTrigger: reminder.triggerType,
                                reminderValue: `${reminder.timeValue} ${reminder.timeUnit}`,
                                taskId: delegation.id,
                                doerName: `${doer.firstName} ${doer.lastName}`,
                                assignerName: assigner ? `${assigner.firstName} ${assigner.lastName}` : 'N/A',
                                voiceNoteUrl: delegation.voiceNoteUrl || 'No audio note',
                                referenceDocs: Array.isArray(delegation.referenceDocs) ? delegation.referenceDocs.join(', ') : (delegation.referenceDocs || 'No reference documents'),
                                evidenceUrl: delegation.evidenceUrl || 'No evidence provided'
                            });
                        }
                    }

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
