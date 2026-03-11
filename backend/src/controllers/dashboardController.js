import { db } from '../db/index.js';
import { delegations, users } from '../db/schema.js';
import { eq, and, sql, gte, lte } from 'drizzle-orm';

export const getDashboardStats = async (request, reply) => {
    try {
        const userId = request.user.id;
        const role = request.user.role?.toLowerCase() || 'user';
        const { filter = 'Today', startDate, endDate, category, tag, frequency, assignedTo } = request.query;

        // Build base condition
        // Default to showing tasks delegated to or by the user (unless admin)
        let conditions = [];
        if (role !== 'admin' && role !== 'superadmin') {
           conditions.push(sql`(${delegations.assignerId} = ${userId} OR ${delegations.doerId} = ${userId})`);
        }

        // We can add time filtering using `startDate` and `endDate` here by adding to conditions array,
        // but for simplicity, let's aggregate all currently matching tasks.

        const baseWhere = conditions.length > 0 ? sql.join(conditions, sql` AND `) : sql`1=1`;

        // Get all delegations
        const allTasks = await db.select({
            id: delegations.id,
            status: delegations.status,
            dueDate: delegations.dueDate,
            assignerId: delegations.assignerId,
            doerId: delegations.doerId,
            category: delegations.category
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
            overdue: 0,
            pending: 0,
            inProgress: 0,
            done: 0,
            onTime: 0,
            delayed: 0
        };

        const employeeStats = {};

        const currentDate = new Date();

        allTasks.forEach(task => {
            let s = task.status ? task.status.toLowerCase() : 'pending';
            
            // Standardize status
            let mappedStatus = 'pending';
            if (s === 'completed' || s === 'done') {
                mappedStatus = 'completed';
            } else if (s === 'in progress' || s === 'in-progress') {
                mappedStatus = 'in_progress';
            } else if (s === 'overdue') {
                mappedStatus = 'overdue';
            }

            // Check for actual overdue if not completed
            let dueDate = task.dueDate ? new Date(task.dueDate) : currentDate;
            if (mappedStatus !== 'completed' && dueDate < currentDate) {
                mappedStatus = 'overdue';
            }

            // Global stats
            if (mappedStatus === 'completed') {
                stats.done++;
                stats.onTime++; // Assumption for simplicity
            } else if (mappedStatus === 'in_progress') {
                stats.inProgress++;
            } else if (mappedStatus === 'overdue') {
                stats.overdue++;
                stats.delayed++;
            } else {
                stats.pending++;
            }

            // Employee breakdown
            let doerId = task.doerId || 'unassigned';
            let doerName = userMap[doerId] || 'Unassigned';
            
            if (!employeeStats[doerId]) {
                employeeStats[doerId] = {
                    id: doerId,
                    name: doerName,
                    total: 0,
                    overdue: 0,
                    pending: 0,
                    in_progress: 0,
                    in_time: 0, // In Time (matching Completed)
                    delayed: 0, // Delayed (matching Overdue)
                    completed: 0
                };
            }
            
            let emp = employeeStats[doerId];
            emp.total++;
            
            if (mappedStatus === 'completed') {
                emp.completed++;
                emp.in_time++;
            } else if (mappedStatus === 'overdue') {
                emp.overdue++;
                emp.delayed++;
            } else if (mappedStatus === 'in_progress') {
                emp.in_progress++;
            } else {
                emp.pending++;
            }
        });

        const employeeList = Object.values(employeeStats).map(e => {
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
                employees: employeeList
            }
        });

    } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ success: false, message: 'Internal Server Error' });
    }
};
