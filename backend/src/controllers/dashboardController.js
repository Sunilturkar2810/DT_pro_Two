import { db } from '../db/index.js';
import { delegations, users } from '../db/schema.js';
import { eq, and, sql, gte, lte } from 'drizzle-orm';

export const getDashboardStats = async (request, reply) => {
    try {
        const userId = request.user.id;
        const role = request.user.role?.toLowerCase() || 'user';
        const { filter = 'All Time', filterStartDate, filterEndDate, category, tag, frequency, assignedTo, tab = 'My Report', search } = request.query;

        // Build base condition
        let conditions = [];

        // Tab-specific filters
        if (tab === 'My Report') {
            conditions.push(eq(delegations.doerId, userId));
        } else if (tab === 'Delegated') {
            conditions.push(eq(delegations.assignerId, userId));
        } else if (tab === 'Overdue') {
            const todayStr = new Date().toISOString().split('T')[0];
            conditions.push(and(
                sql`${delegations.status} != 'Completed'`,
                sql`${delegations.dueDate} < ${todayStr}`
            ));
        } else if (tab === 'Daily') {
            const todayStr = new Date().toISOString().split('T')[0];
            conditions.push(eq(delegations.dueDate, todayStr));
        } else if (tab === 'Monthly') {
            const now = new Date();
            const firstDay = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().split('T')[0];
            const lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0).toISOString().split('T')[0];
            conditions.push(and(gte(delegations.dueDate, firstDay), lte(delegations.dueDate, lastDay)));
        }

        // Apply global filters (Role based)
        if (role !== 'admin' && role !== 'superadmin' && tab !== 'My Report' && tab !== 'Delegated') {
            conditions.push(sql`(${delegations.assignerId} = ${userId} OR ${delegations.doerId} = ${userId} OR ${delegations.inLoopIds}::jsonb @> ${JSON.stringify([userId])}::jsonb)`);
        }

        // Time Filtering (Today, Yesterday, etc.)
        const today = new Date();
        let start, end;
        if (filter === 'Today') {
            start = new Date(today.setHours(0,0,0,0));
            end = new Date(today.setHours(23,59,59,999));
        } else if (filter === 'Yesterday') {
            const yesterday = new Date(today);
            yesterday.setDate(yesterday.getDate() - 1);
            start = new Date(yesterday.setHours(0,0,0,0));
            end = new Date(yesterday.setHours(23,59,59,999));
        }
        // ... (Add other time filters if needed, or if frontend sends date range)
        if (filterStartDate && filterEndDate) {
            conditions.push(gte(delegations.dueDate, filterStartDate));
            conditions.push(lte(delegations.dueDate, filterEndDate));
        }

        // Category/Tag Filters
        if (category && category !== 'All' && category !== 'Category') {
            conditions.push(eq(delegations.category, category));
        }
        if (search) {
            conditions.push(sql`${delegations.taskTitle} ILIKE ${'%' + search + '%'}`);
        }

        const baseWhere = conditions.length > 0 ? and(...conditions) : sql`1=1`;

        // Get all delegations
        const allTasks = await db.select({
            id: delegations.id,
            status: delegations.status,
            dueDate: delegations.dueDate,
            assignerId: delegations.assignerId,
            doerId: delegations.doerId,
            category: delegations.category,
            taskTitle: delegations.taskTitle
        }).from(delegations).where(baseWhere);

        // Fetch users to map names
        const allDbUsers = await db.select({
            userId: users.userId,
            firstName: users.firstName,
            lastName: users.lastName
        }).from(users);
        const userMap = {};
        allDbUsers.forEach(u => {
            userMap[u.userId] = `${u.firstName} ${u.lastName}`.trim();
        });

        const stats = {
            total: allTasks.length,
            overdue: 0,
            pending: 0,
            inProgress: 0,
            done: 0,
            onTime: 0,
            delayed: 0
        };

        const resultStats = {};

        const currentDate = new Date();
        const currentStr = currentDate.toISOString().split('T')[0];

        allTasks.forEach(task => {
            let s = task.status ? task.status.toLowerCase() : 'pending';
            
            let mappedStatus = 'pending';
            if (s === 'completed' || s === 'done') {
                mappedStatus = 'completed';
            } else if (s === 'in progress' || s === 'in-progress') {
                mappedStatus = 'in_progress';
            }

            let dueDateStr = task.dueDate; // format YYYY-MM-DD
            if (mappedStatus !== 'completed' && dueDateStr && dueDateStr < currentStr) {
                mappedStatus = 'overdue';
            }

            // Global stats based on currently filtered tasks
            if (mappedStatus === 'completed') {
                stats.done++;
                stats.onTime++;
            } else if (mappedStatus === 'in_progress') {
                stats.inProgress++;
            } else if (mappedStatus === 'overdue') {
                stats.overdue++;
                stats.delayed++;
            } else {
                stats.pending++;
            }

            // Grouping logic for the Table
            let groupingKey, groupingName;
            if (tab === 'Categories') {
                groupingKey = task.category || 'General';
                groupingName = groupingKey;
            } else if (tab === 'Groups') {
                // For now grouping by category as "Groups" if actual group entity not used
                groupingKey = task.category || 'Unassigned';
                groupingName = groupingKey;
            } else {
                // Default grouping by Employee
                groupingKey = task.doerId || 'unassigned';
                groupingName = userMap[groupingKey] || 'Unassigned';
            }
            
            if (!resultStats[groupingKey]) {
                resultStats[groupingKey] = {
                    id: groupingKey,
                    name: groupingName,
                    total: 0,
                    overdue: 0,
                    pending: 0,
                    in_progress: 0,
                    in_time: 0,
                    delayed: 0,
                    completed: 0
                };
            }
            
            let row = resultStats[groupingKey];
            row.total++;
            
            if (mappedStatus === 'completed') {
                row.completed++;
                row.in_time++;
            } else if (mappedStatus === 'overdue') {
                row.overdue++;
                row.delayed++;
            } else if (mappedStatus === 'in_progress') {
                row.in_progress++;
            } else {
                row.pending++;
            }
        });

        const tableList = Object.values(resultStats).map(e => {
            const score = e.total > 0 ? ((e.completed / e.total) * 100).toFixed(0) : '0';
            return {
                ...e,
                score: `${score}%`
            };
        });

        return reply.send({
            success: true,
            stats,
            tableData: {
                employees: tableList
            }
        });

    } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ success: false, message: 'Internal Server Error' });
    }
};
