import { db } from '../db/index.js';
import { delegations, revisionHistory, remarkHistory, checklistMaster, users, taskReminders } from '../db/schema.js';
import { eq, desc, and, gte, lte, ilike, or, sql, isNull, isNotNull } from 'drizzle-orm';
import { alias } from 'drizzle-orm/pg-core';
import { uploadToS3 } from '../utils/s3.js';
import { createNotification } from './notification.controller.js';
import { logActivity } from '../utils/activityLogger.js';
import { notifyUser } from '../services/notifierService.js';

const assignerAlias = alias(users, 'assigner');
const doerAlias = alias(users, 'doer');

const calculateReminderTime = (dueDate, timeValue, timeUnit, triggerType) => {
    if (!dueDate) return null;
    const date = new Date(dueDate);
    let ms = 0;
    const value = parseInt(timeValue);
    
    if (timeUnit === 'minutes') ms = value * 60 * 1000;
    else if (timeUnit === 'hours') ms = value * 60 * 60 * 1000;
    else if (timeUnit === 'days') ms = value * 24 * 60 * 60 * 1000;

    if (triggerType === 'before') {
        return new Date(date.getTime() - ms);
    } else {
        return new Date(date.getTime() + ms);
    }
};

const formatAttachmentsForEmail = (voiceNoteUrl, referenceDocs, evidenceUrl) => {
    const attachments = [];
    if (voiceNoteUrl) {
        attachments.push({
            filename: voiceNoteUrl.split('/').pop() || 'voice-note.mp3',
            path: voiceNoteUrl
        });
    }
    if (referenceDocs) {
        const docs = Array.isArray(referenceDocs) ? referenceDocs : 
                     (typeof referenceDocs === 'string' ? referenceDocs.split(',') : []);
        
        docs.forEach(url => {
            if (url && typeof url === 'string' && url.trim()) {
                attachments.push({
                    filename: url.trim().split('/').pop() || 'attachment',
                    path: url.trim()
                });
            }
        });
    }
    if (evidenceUrl) {
        attachments.push({
            filename: evidenceUrl.split('/').pop() || 'evidence-file',
            path: evidenceUrl
        });
    }
    return attachments;
};

export const createDelegation = async (req, reply) => {
    const {
        taskTitle,
        description,
        assignerId,
        doerId,
        inLoopIds,
        category,
        priority,
        status,
        dueDate,
        voiceNoteUrl,
        referenceDocs,
        evidenceRequired,
        evidenceUrl,
        checklistItems = [],
        isRepeat,
        repeatFrequency,
        repeatStartDate,
        repeatEndDate,
        repeatIntervalDays,
        weeklyDays,
        selectedDates,
        occurEveryMode,
        customOccurValue,
        customOccurDays,
        customOccurDates,
        tags,
        groupId,
        parentId,
        reminders = []
    } = req.body;

    try {
        const doerIds = Array.isArray(doerId) ? doerId : [doerId];
        const createdDelegations = [];
        const parsedTags = Array.isArray(tags) ? tags : (typeof tags === 'string' ? JSON.parse(tags) : null);

        // Determine today's date string
        const todayStr = new Date().toISOString().split('T')[0];

        // Fetch assigner once
        const [assigner] = await db.select().from(users).where(eq(users.userId, assignerId));
        const taskListStr = checklistItems && checklistItems.length > 0
            ? checklistItems.map(item => `• ${item.text || item.itemName || 'Checklist Item'}`).join('\n')
            : 'No checklist items';

        for (const targetDoerId of doerIds) {
            // For repeat tasks starting today/past, dueDate of the first instance = the start date (today)
            const firstInstanceDueDate = isRepeat && repeatStartDate && repeatStartDate <= todayStr
                ? new Date(repeatStartDate)
                : (dueDate ? new Date(new Date(dueDate).toISOString().split('T')[0]) : null);

            const [newDelegation] = await db.insert(delegations).values({
                taskTitle,
                description,
                assignerId,
                doerId: targetDoerId,
                inLoopIds: inLoopIds || [],
                category,
                priority,
                status: status || 'Pending',
                dueDate: firstInstanceDueDate,
                voiceNoteUrl,
                referenceDocs,
                evidenceRequired: evidenceRequired === true,
                evidenceUrl: evidenceUrl || null,
                revisionCount: 0,
                tags: parsedTags,
                checklistItems: checklistItems,
                groupId: groupId || null,
                parentId: parentId || null
            }).returning();

            createdDelegations.push(newDelegation);

            if (isRepeat) {
                await db.insert(checklistMaster).values({
                    delegationId: newDelegation.id,
                    taskTitle,
                    description,
                    assignerId,
                    doerId: targetDoerId,
                    priority,
                    category,
                    verificationRequired: evidenceRequired === true,
                    attachmentRequired: evidenceRequired === true,
                    voiceNoteUrl,
                    referenceDocs,
                    tags: parsedTags,
                    inLoopIds: inLoopIds || [],
                    checklistItems: checklistItems,
                    frequency: repeatFrequency,
                    fromDate: (repeatStartDate || todayStr) ? new Date(repeatStartDate || todayStr) : null,
                    dueDate: repeatEndDate ? new Date(new Date(repeatEndDate).toISOString().split('T')[0]) : null,
                    weeklyDays: weeklyDays,
                    selectedDates: selectedDates,
                    intervalDays: (repeatIntervalDays && !isNaN(parseInt(repeatIntervalDays))) ? parseInt(repeatIntervalDays) : null,
                    occurEveryMode: occurEveryMode,
                    occurValue: (customOccurValue && !isNaN(parseInt(customOccurValue))) ? parseInt(customOccurValue) : null,
                    occurDays: customOccurDays,
                    occurDates: customOccurDates,
                    groupId: groupId || null
                });
            }

            // Save reminders if any
            if (reminders && reminders.length > 0) {
                const reminderData = reminders.map(r => ({
                    delegationId: newDelegation.id,
                    type: r.type,
                    timeValue: r.timeValue,
                    timeUnit: r.timeUnit,
                    triggerType: r.triggerType,
                    reminderTime: calculateReminderTime(firstInstanceDueDate || dueDate, r.timeValue, r.timeUnit, r.triggerType)
                })).filter(r => r.reminderTime !== null);

                if (reminderData.length > 0) {
                    await db.insert(taskReminders).values(reminderData);
                }
            }

            // Notify the assigned doer (In-app)
            await createNotification(
                targetDoerId,
                'New Task Delegated',
                `You have been assigned a new task: ${taskTitle}`,
                'delegation',
                newDelegation.id
            );

            // Fetch doer details
            const [doer] = await db.select().from(users).where(eq(users.userId, targetDoerId));

            // Notify via External Channels (Email/WhatsApp) based on preferences
            await notifyUser(targetDoerId, 'newTask', {
                title: 'New Task Delegated',
                message: `You have been assigned a new task: ${taskTitle}\nDescription: ${description || 'No description'}\nPriority: ${priority}\nDue Date: ${firstInstanceDueDate ? new Date(firstInstanceDueDate).toLocaleDateString() : 'No due date'}`,
                html: `
                    <div style="font-family: sans-serif; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
                        <h2 style="color: #10b981;">New Task Delegated</h2>
                        <p><strong>Title:</strong> ${taskTitle}</p>
                        <p><strong>Description:</strong> ${description || 'No description'}</p>
                        <p><strong>Priority:</strong> <span style="color: ${priority === 'High' ? '#ef4444' : '#6b7280'};">${priority}</span></p>
                        <p><strong>Due Date:</strong> ${firstInstanceDueDate ? new Date(firstInstanceDueDate).toLocaleDateString() : 'No due date'}</p>
                        <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
                        <p style="font-size: 12px; color: #6b7280;">Please log in to the portal to view more details.</p>
                    </div>
                `,
                // Variables for templates
                taskTitle,
                taskDescription: description || 'No description',
                priority,
                category,
                dueDate: firstInstanceDueDate ? new Date(firstInstanceDueDate).toLocaleDateString() : 'No due date',
                assignerName: assigner ? `${assigner.firstName} ${assigner.lastName}` : 'Assigner',
                doerName: doer ? `${doer.firstName} ${doer.lastName}` : 'You',
                status: status || 'Pending',
                attachments: formatAttachmentsForEmail(voiceNoteUrl, referenceDocs, evidenceUrl),
                taskList: taskListStr
            });

            // Log activity
            await logActivity({
                type: parentId ? 'subtask_created' : 'task_created',
                title: taskTitle,
                description: parentId ? `New sub task added [${taskTitle}]` : `Task assigned: ${taskTitle}`,
                userId: assignerId,
                relatedId: newDelegation.id,
                relatedType: 'task'
            });
        }

        return reply.status(201).send({
            success: true,
            message: 'Delegation(s) created successfully',
            data: createdDelegations[0]
        });
    } catch (error) {
        req.log.error(error);
        return reply.status(500).send({
            success: false,
            message: 'Failed to create delegation',
            error: error.message
        });
    }
};

export const createDelegationTemplate = async (req, reply) => {
    const {
        templateName,
        description,
        assignedDoerId,
        category,
        priority,
        status,
        dueDate,
        voiceNoteUrl,
        referenceDocs,
        evidenceRequired,
        checklistItems = [],
        isRepeat,
        repeatFrequency,
        repeatEndDate,
        customRepeatValue,
        customRepeatUnit
    } = req.body;

    try {
        const storedUser = req.user; // Assuming req.user is set via auth middleware
        const delegatorId = storedUser?.userId || storedUser?.id;

        // The user specifies 2 tables for task templates: task_template_checklist_master and task_template_checklist.
        // Similar to delegations, the master table acts as the main structure.
        let masterId = null;

        const combinedFrequency = repeatFrequency === 'Custom' ? `${customRepeatValue} ${customRepeatUnit}` : repeatFrequency;

        // If it's a template, the template itself goes to taskTemplateChecklistMaster
        const [newTemplateMaster] = await db.insert(taskTemplateChecklistMaster).values({
            itemName: templateName, // Treat templateName as item_name
            assigneeId: delegatorId,
            doerId: assignedDoerId,
            priority,
            category,
            verificationRequired: evidenceRequired || false,
            attachmentRequired: evidenceRequired || false,
            frequency: isRepeat ? combinedFrequency : null,
            dueDate: repeatEndDate ? new Date(new Date(repeatEndDate).toISOString().split('T')[0]) : null,
        }).returning();

        masterId = newTemplateMaster.id;

        // If there are specific checklist items inside the template, we link them to this master
        if (checklistItems && checklistItems.length > 0) {
            for (const item of checklistItems) {
                await db.insert(taskTemplateChecklist).values({
                    masterId,
                    itemName: item.text || item.itemName || '',
                    assigneeId: delegatorId,
                    doerId: assignedDoerId,
                    priority,
                    category,
                    verificationRequired: evidenceRequired || false,
                    attachmentRequired: evidenceRequired || false,
                    frequency: isRepeat ? combinedFrequency : null,
                    status: 'Pending',
                    dueDate: repeatEndDate ? new Date(new Date(repeatEndDate).toISOString().split('T')[0]) : null,
                });
            }
        } else {
            // If no nested checklist, just create one item for the master so it can spawn
            await db.insert(taskTemplateChecklist).values({
                masterId,
                itemName: templateName,
                assigneeId: delegatorId,
                doerId: assignedDoerId,
                priority,
                category,
                verificationRequired: evidenceRequired || false,
                attachmentRequired: evidenceRequired || false,
                frequency: isRepeat ? combinedFrequency : null,
                status: 'Pending',
                dueDate: repeatEndDate ? new Date(new Date(repeatEndDate).toISOString().split('T')[0]) : null,
            });
        }

        return reply.status(201).send({
            success: true,
            message: 'Task Template created successfully',
            data: newTemplateMaster
        });

    } catch (error) {
        req.log.error(error);
        return reply.status(500).send({
            success: false,
            message: 'Failed to create task template',
            error: error.message
        });
    }
};

    export const getDelegations = async (req, reply) => {
        try {
            const { doerId, assignerId, startDate, endDate, search, category, groupId, tag, frequency } = req.query;
            let conditions = [];
    
            if (doerId) {
                conditions.push(eq(delegations.doerId, doerId));
            }
    
            if (groupId) {
                conditions.push(eq(delegations.groupId, groupId));
            }
    
            if (assignerId) {
                conditions.push(eq(delegations.assignerId, assignerId));
            }
    
            if (category && category !== 'Category' && category !== 'undefined') {
                conditions.push(ilike(delegations.category, category));
            }
            
            if (tag && tag !== 'Tag' && tag !== 'undefined') {
                conditions.push(sql`${delegations.tags}::text ILIKE ${`%${tag}%`}`);
            }
            
            if (frequency && frequency !== 'Frequency' && frequency !== 'undefined') {
                if (frequency.toLowerCase() === 'once') {
                    conditions.push(or(
                        sql`${checklistMaster.frequency} IS NULL`,
                        eq(checklistMaster.frequency, 'Once')
                    ));
                } else {
                    conditions.push(ilike(checklistMaster.frequency, frequency));
                }
            }
    
            if (startDate) {
                conditions.push(gte(delegations.createdAt, new Date(startDate)));
            }
    
            if (endDate) {
                conditions.push(lte(delegations.createdAt, new Date(endDate)));
            }
    
            if (search) {
                conditions.push(or(
                    ilike(delegations.taskTitle, `%${search}%`),
                    ilike(delegations.description, `%${search}%`)
                ));
            }

        let queryBuilder = db.select({
            id: delegations.id,
            taskTitle: delegations.taskTitle,
            description: delegations.description,
            assignerId: delegations.assignerId,
            doerId: delegations.doerId,
            category: delegations.category,
            priority: delegations.priority,
            status: delegations.status,
            dueDate: delegations.dueDate,
            voiceNoteUrl: delegations.voiceNoteUrl,
            referenceDocs: delegations.referenceDocs,
            tags: delegations.tags,
            checklistItems: delegations.checklistItems,
            evidenceRequired: delegations.evidenceRequired,
            evidenceUrl: delegations.evidenceUrl,
            revisionCount: delegations.revisionCount,
            inLoopIds: delegations.inLoopIds,
            groupId: delegations.groupId,
            createdAt: delegations.createdAt,
            updatedAt: delegations.updatedAt,
            assignerFirstName: assignerAlias.firstName,
            assignerLastName: assignerAlias.lastName,
            doerFirstName: doerAlias.firstName,
            doerLastName: doerAlias.lastName,
            frequency: checklistMaster.frequency
        })
        .from(delegations)
        .leftJoin(assignerAlias, eq(delegations.assignerId, assignerAlias.userId))
        .leftJoin(doerAlias, eq(delegations.doerId, doerAlias.userId))
        .leftJoin(checklistMaster, eq(delegations.id, checklistMaster.delegationId));

        // Always exclude soft-deleted records from normal queries
        conditions.push(isNull(delegations.deletedAt));

        queryBuilder = queryBuilder.where(and(...conditions));

        const allDelegations = await queryBuilder.orderBy(desc(delegations.createdAt));

        return reply.status(200).send({
            success: true,
            data: allDelegations
        });
    } catch (error) {
        req.log.error(error);
        return reply.status(500).send({
            success: false,
            message: 'Failed to fetch delegations',
            error: error.message
        });
    }
};

export const getDelegationById = async (req, reply) => {
    const { id } = req.params;

    try {
        const [delegation] = await db.select().from(delegations).where(eq(delegations.id, id));

        if (!delegation) {
            return reply.status(404).send({
                success: false,
                message: 'Delegation not found'
            });
        }

        const revisions = await db.select().from(revisionHistory).where(eq(revisionHistory.delegationId, id)).orderBy(desc(revisionHistory.createdAt));
        const remarks = await db.select().from(remarkHistory).where(eq(remarkHistory.delegationId, id)).orderBy(desc(remarkHistory.createdAt));

        return reply.status(200).send({
            success: true,
            data: {
                ...delegation,
                revision_history: revisions,
                remarks: remarks,
                checklistItems: delegation.checklistItems || [],
                reminders: await db.select().from(taskReminders).where(eq(taskReminders.delegationId, id)),
                subtasks: await db.select().from(delegations).where(eq(delegations.parentId, id)).orderBy(desc(delegations.createdAt))
            }
        });
    } catch (error) {
        req.log.error(error);
        return reply.status(500).send({
            success: false,
            message: 'Failed to fetch delegation details',
            error: error.message
        });
    }
};

export const updateDelegation = async (req, reply) => {
    const { id } = req.params;
    const updates = req.body;
    const { changedBy, reason } = updates;

    try {
        const [existingDelegation] = await db.select().from(delegations).where(eq(delegations.id, id));

        if (!existingDelegation) {
            return reply.status(404).send({
                success: false,
                message: 'Delegation not found'
            });
        }

        const newDueDate = updates.dueDate ? new Date(new Date(updates.dueDate).toISOString().split('T')[0]) : existingDelegation.dueDate;
        const isDueDateChanged = updates.dueDate && newDueDate !== existingDelegation.dueDate;
        const isStatusChanged = updates.status && updates.status !== existingDelegation.status;

        let revisionCount = existingDelegation.revisionCount || 0;

        if (isDueDateChanged || isStatusChanged) {
            try {
                await db.insert(revisionHistory).values({
                    delegationId: id,
                    oldDueDate: existingDelegation.dueDate,
                    newDueDate: newDueDate,
                    oldStatus: existingDelegation.status,
                    newStatus: updates.status || existingDelegation.status,
                    reason: reason || 'Update',
                    changedBy: changedBy || existingDelegation.assignerId,
                });
                revisionCount += 1;
            } catch (revError) {
                req.log.error('Failed to create revision history entry:', revError);
            }
        }

        // Clean up updates object to only include delegation fields
        const delegationFields = [
            'taskTitle', 'description', 'assignerId', 'doerId',
            'category', 'priority', 'status', 'voiceNoteUrl',
            'referenceDocs', 'evidenceRequired', 'evidenceUrl', 'inLoopIds',
            'checklistItems', 'tags'
        ];

        const filteredUpdates = {};
        for (const field of delegationFields) {
            if (updates[field] !== undefined) {
                filteredUpdates[field] = updates[field];
            }
        }

        if (updates.dueDate) {
            filteredUpdates.dueDate = newDueDate;
        }

        filteredUpdates.revisionCount = revisionCount;
        filteredUpdates.updatedAt = new Date();

        const [updatedDelegation] = await db.update(delegations)
            .set(filteredUpdates)
            .returning();

        // Sync reminders if provided in updates
        if (updates.reminders) {
            // Remove old reminders
            await db.delete(taskReminders).where(eq(taskReminders.delegationId, id));
            
            // Add new ones
            const reminderData = updates.reminders.map(r => ({
                delegationId: id,
                type: r.type,
                timeValue: r.timeValue,
                timeUnit: r.timeUnit,
                triggerType: r.triggerType,
                reminderTime: calculateReminderTime(updatedDelegation.dueDate, r.timeValue, r.timeUnit, r.triggerType)
            })).filter(r => r.reminderTime !== null);

            if (reminderData.length > 0) {
                await db.insert(taskReminders).values(reminderData);
            }
        } else if (isDueDateChanged) {
            // If due date changed but reminders weren't explicitly updated, recalculate reminderTimes
            const existingReminders = await db.select().from(taskReminders).where(eq(taskReminders.delegationId, id));
            for (const r of existingReminders) {
                const updatedTime = calculateReminderTime(updatedDelegation.dueDate, r.timeValue, r.timeUnit, r.triggerType);
                await db.update(taskReminders)
                    .set({ reminderTime: updatedTime, updatedAt: new Date() })
                    .where(eq(taskReminders.id, r.id));
            }
        }

        // Notify relevant party about updates
        const recipientId = changedBy === existingDelegation.assignerId
            ? existingDelegation.doerId
            : existingDelegation.assignerId;

        let title = 'Task Updated';
        let message = `Task "${existingDelegation.taskTitle}" has been updated.`;

        if (isStatusChanged) {
            title = 'Task Status Changed';
            message = `Status of task "${existingDelegation.taskTitle}" changed to ${updates.status}`;
        } else if (isDueDateChanged) {
            title = 'Task Deadline Updated';
            message = `Deadline of task "${existingDelegation.taskTitle}" updated to ${newDueDate}`;
        }

        await createNotification(
            recipientId,
            title,
            message,
            isStatusChanged ? 'status_change' : 'revision',
            id
        );

        // Notify via External Channels (Email/WhatsApp)
        const updater = req.user;
        const updaterName = updater ? `${updater.firstName} ${updater.lastName}` : 'System';
        
        // Determine notification event type
        let eventType = 'taskEdit';
        if (isStatusChanged) {
            if (updates.status === 'Completed') {
                eventType = 'taskComplete';
            } else if (existingDelegation.status === 'Completed' && (updates.status === 'Pending' || updates.status === 'In Progress' || updates.status === 'Late')) {
                eventType = 'taskReOpen';
            } else if (updates.status === 'In Progress') {
                eventType = 'taskInProgress';
            }
        }

        await notifyUser(recipientId, eventType, {
            title,
            message: `${message}\nTask: ${existingDelegation.taskTitle}\nUpdated by: ${updaterName}`,
            html: `
                <div style="font-family: sans-serif; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
                    <h2 style="color: #f59e0b;">${title}</h2>
                    <p>${message}</p>
                    <p><strong>Task:</strong> ${existingDelegation.taskTitle}</p>
                    <p><strong>Updated by:</strong> ${updaterName}</p>
                    <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
                    <p style="font-size: 12px; color: #6b7280;">Please log in to the portal to view more details.</p>
                </div>
            `,
            // Variables for templates
            taskTitle: existingDelegation.taskTitle,
            message,
            updatedBy: updaterName,
            priority: existingDelegation.priority,
            dueDate: existingDelegation.dueDate ? new Date(existingDelegation.dueDate).toLocaleDateString() : 'No due date',
            status: updates.status || existingDelegation.status,
            attachments: formatAttachmentsForEmail(updatedDelegation.voiceNoteUrl, updatedDelegation.referenceDocs, updatedDelegation.evidenceUrl),
            taskList: (updatedDelegation.checklistItems && updatedDelegation.checklistItems.length > 0)
                ? updatedDelegation.checklistItems.map(item => `• ${item.text || item.itemName || 'Checklist Item'}`).join('\n')
                : 'No checklist items'
        });

        // Log activity
        await logActivity({
            type: isStatusChanged ? 'status_change' : 'revision',
            title: updatedDelegation.taskTitle,
            description: isStatusChanged 
                ? `Status of task "${updatedDelegation.taskTitle}" changed to ${updates.status}`
                : `Task "${updatedDelegation.taskTitle}" was updated/revised`,
            userId: changedBy || existingDelegation.assignerId,
            relatedId: id,
            relatedType: 'task',
            metadata: {
                oldStatus: existingDelegation.status,
                newStatus: updates.status,
                oldDueDate: existingDelegation.dueDate,
                newDueDate: updates.dueDate
            }
        });

        return reply.status(200).send({
            success: true,
            message: 'Delegation updated successfully',
            data: updatedDelegation
        });
    } catch (error) {
        req.log.error(error);
        return reply.status(500).send({
            success: false,
            message: 'Failed to update delegation',
            error: error.message
        });
    }
};

export const deleteDelegation = async (req, reply) => {
    const { id } = req.params;
    const { deletedBy } = req.body || {};

    try {
        const [existing] = await db.select().from(delegations).where(eq(delegations.id, id));
        if (!existing) {
            return reply.status(404).send({ success: false, message: 'Delegation not found' });
        }

        // Soft delete — set deletedAt timestamp instead of removing
        const [softDeleted] = await db.update(delegations)
            .set({
                deletedAt: new Date(),
                deletedBy: deletedBy || existing.assignerId,
                updatedAt: new Date()
            })
            .where(eq(delegations.id, id))
            .returning();

        // Log activity
        await logActivity({
            type: 'deleted',
            title: existing.taskTitle,
            description: `Task "${existing.taskTitle}" moved to trash`,
            userId: deletedBy || existing.assignerId,
            relatedId: id,
            relatedType: 'task'
        });

        return reply.status(200).send({
            success: true,
            message: 'Delegation moved to trash',
            data: softDeleted
        });
    } catch (error) {
        req.log.error(error);
        return reply.status(500).send({
            success: false,
            message: 'Failed to delete delegation',
            error: error.message
        });
    }
};

export const getDeletedDelegations = async (req, reply) => {
    try {
        const { startDate, endDate, search, status } = req.query;
        let conditions = [isNotNull(delegations.deletedAt)];

        if (startDate) conditions.push(gte(delegations.deletedAt, new Date(startDate)));
        if (endDate) {
            const end = new Date(endDate);
            end.setHours(23, 59, 59, 999);
            conditions.push(lte(delegations.deletedAt, end));
        }
        if (search) {
            conditions.push(or(
                ilike(delegations.taskTitle, `%${search}%`),
                ilike(delegations.description, `%${search}%`)
            ));
        }
        if (status && status !== 'All') {
            conditions.push(eq(delegations.status, status));
        }

        const deletedBy = alias(users, 'deleted_by_user');

        const results = await db.select({
            id: delegations.id,
            taskTitle: delegations.taskTitle,
            description: delegations.description,
            assignerId: delegations.assignerId,
            doerId: delegations.doerId,
            category: delegations.category,
            priority: delegations.priority,
            status: delegations.status,
            dueDate: delegations.dueDate,
            groupId: delegations.groupId,
            tags: delegations.tags,
            checklistItems: delegations.checklistItems,
            deletedAt: delegations.deletedAt,
            deletedBy: delegations.deletedBy,
            createdAt: delegations.createdAt,
            assignerFirstName: assignerAlias.firstName,
            assignerLastName: assignerAlias.lastName,
            doerFirstName: doerAlias.firstName,
            doerLastName: doerAlias.lastName,
            deletedByFirstName: deletedBy.firstName,
            deletedByLastName: deletedBy.lastName,
        })
        .from(delegations)
        .leftJoin(assignerAlias, eq(delegations.assignerId, assignerAlias.userId))
        .leftJoin(doerAlias, eq(delegations.doerId, doerAlias.userId))
        .leftJoin(deletedBy, eq(delegations.deletedBy, deletedBy.userId))
        .where(and(...conditions))
        .orderBy(desc(delegations.deletedAt));

        return reply.status(200).send({ success: true, data: results });
    } catch (error) {
        req.log.error(error);
        return reply.status(500).send({ success: false, message: 'Failed to fetch deleted delegations', error: error.message });
    }
};

export const restoreDelegation = async (req, reply) => {
    const { id } = req.params;
    try {
        const [existing] = await db.select().from(delegations).where(eq(delegations.id, id));
        if (!existing || !existing.deletedAt) {
            return reply.status(404).send({ success: false, message: 'Deleted delegation not found' });
        }

        const [restored] = await db.update(delegations)
            .set({ deletedAt: null, deletedBy: null, updatedAt: new Date() })
            .where(eq(delegations.id, id))
            .returning();

        // Log activity
        await logActivity({
            type: 'restored',
            title: restored.taskTitle,
            description: `Task "${restored.taskTitle}" restored from trash`,
            userId: restored.assignerId, // Assuming assigner or person who restored? 
            relatedId: id,
            relatedType: 'task'
        });

        return reply.status(200).send({ success: true, message: 'Delegation restored successfully', data: restored });
    } catch (error) {
        req.log.error(error);
        return reply.status(500).send({ success: false, message: 'Failed to restore delegation', error: error.message });
    }
};

export const addRemark = async (req, reply) => {
    const { id } = req.params;
    const { userId, remark } = req.body;

    try {
        const [newRemark] = await db.insert(remarkHistory).values({
            delegationId: id,
            userId,
            remark
        }).returning();

        // Get delegation to identify the other party
        const [delegation] = await db.select().from(delegations).where(eq(delegations.id, id));
        if (delegation) {
            const recipientId = userId === delegation.assignerId
                ? delegation.doerId
                : delegation.assignerId;

            await createNotification(
                recipientId,
                'New Remark Added',
                `A new remark has been added to task: ${delegation.taskTitle}`,
                'remark',
                id
            );

            // Notify via External Channels (Email/WhatsApp)
            const commenter = await db.select().from(users).where(eq(users.userId, userId)).limit(1);
            const commenterName = commenter[0] ? `${commenter[0].firstName} ${commenter[0].lastName}` : 'Someone';

            await notifyUser(recipientId, 'taskComment', {
                title: 'New Remark Added',
                message: `A new remark has been added to task "${delegation.taskTitle}" by ${commenterName}: ${remark}`,
                html: `
                    <div style="font-family: sans-serif; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
                        <h2 style="color: #6366f1;">New Remark Added</h2>
                        <p><strong>Task:</strong> ${delegation.taskTitle}</p>
                        <p><strong>Remark:</strong> ${remark}</p>
                        <p><strong>Added by:</strong> ${commenterName}</p>
                        <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
                        <p style="font-size: 12px; color: #6b7280;">Please log in to the portal to view more details.</p>
                    </div>
                `,
                // Variables for templates
                taskTitle: delegation.taskTitle,
                remark,
                commenterName,
                priority: delegation.priority,
                category: delegation.category,
                dueDate: delegation.dueDate ? new Date(delegation.dueDate).toLocaleDateString() : 'No due date',
                status: delegation.status
            });

            // Log activity
            await logActivity({
                type: 'remark',
                title: delegation.taskTitle,
                description: remark,
                userId: userId,
                relatedId: id,
                relatedType: 'task'
            });
        }

        return reply.status(201).send({
            success: true,
            message: 'Remark added successfully',
            data: newRemark
        });
    } catch (error) {
        req.log.error(error);
        return reply.status(500).send({
            success: false,
            message: 'Failed to add remark',
            error: error.message
        });
    }
};

export const uploadFile = async (req, reply) => {
    try {
        const data = await req.file();
        if (!data) {
            return reply.status(400).send({ success: false, message: 'No file uploaded' });
        }

        const buffer = await data.toBuffer();
        const fileName = data.filename;
        const folder = req.query.folder || 'general';

        const url = await uploadToS3(buffer, fileName, folder);

        return reply.status(200).send({
            success: true,
            message: 'File uploaded successfully',
            url: url
        });
    } catch (error) {
        req.log.error(error);
        return reply.status(500).send({
            success: false,
            message: 'Failed to upload file',
            error: error.message
        });
    }
};
