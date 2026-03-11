import cron from 'node-cron';
import { db } from '../db/index.js';
import { checklistMaster, checklist } from '../db/schema.js';
import { eq } from 'drizzle-orm';

const generateTasksForTomorrow = async () => {
    console.log('Running daily task generation at 11:50 PM');
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const tomorrowStr = tomorrow.toISOString().split('T')[0];
    const dayOfWeek = tomorrow.toLocaleDateString('en-US', { weekday: 'long' });
    const dayOfMonth = tomorrow.getDate().toString().padStart(2, '0');
    const monthNameArray = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const monthName = monthNameArray[tomorrow.getMonth()];

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
                    // Handle "Last Day"
                    if (master.selectedDates.includes('Last Day')) {
                        const nextAfterTomorrow = new Date(tomorrow);
                        nextAfterTomorrow.setDate(tomorrow.getDate() + 1);
                        if (nextAfterTomorrow.getDate() === 1) { // Tomorrow is the last day of its month
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
                const occurEvery = master.occurEveryMode; // 'Week' or 'Month'
                const occurValue = master.occurValue || 1;

                if (occurEvery === 'Week') {
                    // Check if it's the right week and the right day
                    const diffWeeks = Math.floor(diffDays / 7);
                    if (diffDays % 7 === 0 || diffWeeks % occurValue === 0) {
                        // Actually, we just need to check if we are in a week that is a multiple of occurValue from startDate
                        // and if today is one of the selected days.
                        const startWeekDate = new Date(startDate);
                        const dayOff = startDate.getDay(); // 0 is Sunday
                        startWeekDate.setDate(startDate.getDate() - (dayOff === 0 ? 6 : dayOff - 1)); // Set to Monday of start week
                        
                        const tomorrowWeekDate = new Date(tomorrowZero);
                        tomorrowWeekDate.setDate(tomorrowZero.getDate() - (tomorrowZero.getDay() === 0 ? 6 : tomorrowZero.getDay() - 1));
                        
                        const weekDiffDays = Math.floor((tomorrowWeekDate - startWeekDate) / (1000 * 60 * 60 * 24));
                        const weekDiff = Math.floor(weekDiffDays / 7);
                        
                        if (weekDiff >= 0 && weekDiff % occurValue === 0) {
                            if (master.occurDays && Array.isArray(master.occurDays) && master.occurDays.includes(dayOfWeek)) {
                                shouldCreate = true;
                            }
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
                await db.insert(checklist).values({
                    masterId: master.id,
                    delegationId: master.delegationId,
                    itemName: master.itemName,
                    assigneeId: master.assigneeId,
                    doerId: master.doerId,
                    priority: master.priority,
                    category: master.category,
                    verificationRequired: master.verificationRequired,
                    attachmentRequired: master.attachmentRequired,
                    frequency: master.frequency,
                    status: 'Pending',
                    dueDate: tomorrowStr
                });
                console.log(`Generated task for ${tomorrowStr}: ${master.itemName}`);
            }
        }
    } catch (error) {
        console.error('Error in daily task generation:', error);
    }
};

export const initCron = () => {
    // 50 23 * * * = 11:50 PM every day
    // Using 11:50 PM as requested.
    cron.schedule('50 23 * * *', generateTasksForTomorrow);
    console.log('Task generation cron job initialized (Runs at 11:50 PM daily)');
};
