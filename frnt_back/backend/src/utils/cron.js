import cron from 'node-cron';
import { db } from '../db/index.js';
import { checklistMaster, delegations, users, notificationPreferences } from '../db/schema.js';
import { createNotification } from '../controllers/notification.controller.js';
import { initReminderWorker } from '../workers/reminderWorker.js';
import { and, eq } from 'drizzle-orm';
import { notifyUser } from '../services/notifierService.js';

const generateTasksForTomorrow = async () => {
    console.log('Running daily task generation at 11:50 PM');
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const tomorrowStr = tomorrow.toISOString().split('T')[0];
    const dayOfWeek = tomorrow.toLocaleDateString('en-US', { weekday: 'long' });

    try {
        const masters = await db.select().from(checklistMaster);
        
        for (const master of masters) {
            let shouldCreate = false;
            const freq = master.frequency;
            if (!freq) continue;

            // Check if start date is in the future
            if (master.fromDate && new Date(master.fromDate) > tomorrow) {
                continue;
            }

            // Check if repeatEndDate is passed
            if (master.dueDate && new Date(master.dueDate) < tomorrow) {
                continue;
            }

            const startDate = new Date(master.fromDate || master.createdAt);
            startDate.setHours(0, 0, 0, 0);
            const tomorrowZero = new Date(tomorrow);
            tomorrowZero.setHours(0, 0, 0, 0);

            const diffTime = tomorrowZero - startDate;
            const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));

            if (freq === 'Daily') {
                shouldCreate = true;
            } else if (freq === 'Weekly') {
                if (master.weeklyDays && Array.isArray(master.weeklyDays) && master.weeklyDays.includes(dayOfWeek)) {
                    shouldCreate = true;
                }
            } else if (freq === 'Monthly') {
                if (master.selectedDates && Array.isArray(master.selectedDates)) {
                    const dStr = tomorrow.getDate().toString();
                    if (master.selectedDates.includes(dStr)) {
                        shouldCreate = true;
                    }
                    if (master.selectedDates.includes('Last Day')) {
                        const nextAfterTomorrow = new Date(tomorrow);
                        nextAfterTomorrow.setDate(tomorrow.getDate() + 1);
                        if (nextAfterTomorrow.getDate() === 1) {
                            shouldCreate = true;
                        }
                    }
                }
            } else if (freq === 'Yearly') {
                if (startDate.getDate() === tomorrow.getDate() && startDate.getMonth() === tomorrow.getMonth()) {
                    shouldCreate = true;
                }
            } else if (freq === 'Periodically') {
                const interval = master.intervalDays || 1;
                if (diffDays >= 0 && diffDays % interval === 0) {
                    shouldCreate = true;
                }
            } else if (freq === 'Custom') {
                const occurEvery = master.occurEveryMode;
                const occurValue = master.occurValue || 1;

                if (occurEvery === 'Week') {
                    const startWeekDate = new Date(startDate);
                    const dayOff = startDate.getDay();
                    startWeekDate.setDate(startDate.getDate() - (dayOff === 0 ? 6 : dayOff - 1));
                    
                    const tomorrowWeekDate = new Date(tomorrowZero);
                    tomorrowWeekDate.setDate(tomorrowZero.getDate() - (tomorrowZero.getDay() === 0 ? 6 : tomorrowZero.getDay() - 1));
                    
                    const weekDiffDays = Math.floor((tomorrowWeekDate - startWeekDate) / (1000 * 60 * 60 * 24));
                    const weekDiff = Math.floor(weekDiffDays / 7);
                    
                    if (weekDiff >= 0 && weekDiff % occurValue === 0) {
                        if (master.occurDays && Array.isArray(master.occurDays) && master.occurDays.includes(dayOfWeek)) {
                            shouldCreate = true;
                        }
                    }
                } else if (occurEvery === 'Month') {
                    const monthDiff = (tomorrow.getFullYear() - startDate.getFullYear()) * 12 + (tomorrow.getMonth() - startDate.getMonth());
                    if (monthDiff >= 0 && monthDiff % occurValue === 0) {
                        const dStr = tomorrow.getDate().toString();
                        if (master.occurDates && Array.isArray(master.occurDates) && master.occurDates.includes(dStr)) {
                            shouldCreate = true;
                        }
                    }
                }
            }

            if (shouldCreate) {
                const [newDelegation] = await db.insert(delegations).values({
                    taskTitle: master.taskTitle,
                    description: master.description,
                    assignerId: master.assignerId,
                    doerId: master.doerId,
                    category: master.category,
                    priority: master.priority,
                    status: 'Pending',
                    dueDate: tomorrowStr,
                    voiceNoteUrl: master.voiceNoteUrl,
                    referenceDocs: master.referenceDocs,
                    tags: master.tags,
                    inLoopIds: master.inLoopIds,
                    checklistItems: master.checklistItems,
                    evidenceRequired: master.verificationRequired,
                    groupId: master.groupId
                }).returning();

                await createNotification(
                    master.doerId,
                    'Recurring Task Instance Created',
                    `New instance of your recurring task "${master.taskTitle}" has been created for tomorrow.`,
                    'delegation',
                    newDelegation.id
                );
                
                console.log(`Generated delegation instance for ${tomorrowStr}: ${master.taskTitle}`);
            }
        }
    } catch (error) {
        console.error('Error in daily task generation:', error);
    }
};

const sendDailyTaskReports = async () => {
    const now = new Date();
    // Format to HH:mm in Asia/Kolkata
    const currentTime = now.toLocaleTimeString('en-GB', { 
        hour: '2-digit', 
        minute: '2-digit',
        hour12: false,
        timeZone: 'Asia/Kolkata'
    });

    try {
        console.log(`[Cron] Checking daily reports for time: ${currentTime}`);
        const prefs = await db.select()
            .from(notificationPreferences)
            .where(
                and(
                    eq(notificationPreferences.dailyTaskReport, true),
                    eq(notificationPreferences.dailyReminderTime, currentTime)
                )
            );

        if (prefs.length > 0) {
            console.log(`[Cron] Found ${prefs.length} users with daily report scheduled for ${currentTime}`);
        }

        for (const pref of prefs) {
            const user = await db.query.users.findFirst({
                where: eq(users.userId, pref.userId)
            });

            if (!user) {
                console.log(`[Cron] User not found for pref ${pref.id}`);
                continue;
            }

            const pendingTasks = await db.select()
                .from(delegations)
                .where(
                    and(
                        eq(delegations.doerId, user.userId),
                        eq(delegations.status, 'Pending')
                    )
                );

            if (pendingTasks.length === 0) {
                console.log(`[Cron] No pending tasks for user ${user.userId}, skipping report.`);
                continue;
            }

            console.log(`[Cron] Sending daily report to ${user.workEmail} (${pendingTasks.length} tasks)`);
            const taskList = pendingTasks.map(t => `- ${t.taskTitle}${t.dueDate ? ` (Due: ${new Date(t.dueDate).toLocaleDateString()})` : ''}`).join('\n');

            await notifyUser(user.userId, 'dailyPendingReminders', {
                taskList,
                title: 'Daily Task Report',
                message: `You have ${pendingTasks.length} pending tasks.\n\nTasks:\n${taskList}`,
                taskId: 'Multiple',
                taskTitle: 'Daily Pending Tasks',
                category: 'Summary',
                priority: 'N/A',
                status: 'Pending',
                assignerName: 'System',
                doerName: `${user.firstName} ${user.lastName}`,
                taskDescription: `You have ${pendingTasks.length} pending tasks.\n\n${taskList}`
            });
            
            console.log(`[Cron] Successfully processed daily task report for user ${user.userId}`);
        }
    } catch (error) {
        console.error('[Cron] Error in sendDailyTaskReports:', error);
    }
};

export const initCron = () => {
    // 50 23 * * * = 11:50 PM every day
    // Using 11:50 PM as requested.
    cron.schedule('50 23 * * *', generateTasksForTomorrow);
    console.log('Task generation cron job initialized (Runs at 11:50 PM daily)');
    
    // Daily Task Report (Runs every minute to check if any user's scheduled time matches)
    cron.schedule('* * * * *', sendDailyTaskReports);
    console.log('Daily task report cron job initialized (Checks every minute)');
    
    // Task Reminders Worker
    initReminderWorker();
};
