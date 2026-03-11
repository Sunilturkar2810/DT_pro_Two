import { db } from '../db/index.js';
import { delegations, revisionHistory, remarkHistory, checklistMaster, checklist, taskTemplateChecklistMaster, taskTemplateChecklist } from '../db/schema.js';
import { eq, desc, and, gte, lte, ilike, or } from 'drizzle-orm';
import { uploadToS3 } from '../utils/s3.js';
import { createNotification } from './notification.controller.js';

export const createDelegation = async (req, reply) => {
    const {
        taskTitle,
        description,
        assignerId,
        doerId, // Now expected as single or array depends on logic, but controller treats as array usually from frontend
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
        asset
    } = req.body;

    try {
        const doerIds = Array.isArray(doerId) ? doerId : [doerId];
        const createdDelegations = [];

        for (const targetDoerId of doerIds) {
            const [newDelegation] = await db.insert(delegations).values({
                taskTitle,
                description,
                assignerId,
                doerId: targetDoerId,
                inLoopIds: inLoopIds || [],
                category,
                priority,
                status: status || 'Pending',
                dueDate: dueDate ? new Date(dueDate).toISOString().split('T')[0] : null,
                voiceNoteUrl,
                referenceDocs,
                evidenceRequired: evidenceRequired === true,
                evidenceUrl: evidenceUrl || null,
                revisionCount: 0,
                tags: (typeof tags === 'object' && tags !== null) ? tags : (typeof tags === 'string' ? JSON.parse(tags) : null),
                // asset: asset || null
            }).returning();

            createdDelegations.push(newDelegation);

            if (checklistItems && checklistItems.length > 0) {
                for (const item of checklistItems) {
                    let currentMasterId = null;

                    if (isRepeat) {
                        const [newMaster] = await db.insert(checklistMaster).values({
                            delegationId: newDelegation.id,
                            itemName: item.text || item.itemName || '',
                            assignerId: assignerId,
                            doerId: targetDoerId,
                            priority: priority,
                            category: category,
                            verificationRequired: evidenceRequired === true,
                            attachmentRequired: evidenceRequired === true,
                            frequency: repeatFrequency,
                            fromDate: repeatStartDate || (dueDate ? new Date(dueDate).toISOString().split('T')[0] : null),
                            dueDate: repeatEndDate ? new Date(repeatEndDate).toISOString().split('T')[0] : null,
                            weeklyDays: weeklyDays,
                            selectedDates: selectedDates,
                            intervalDays: (repeatIntervalDays && !isNaN(parseInt(repeatIntervalDays))) ? parseInt(repeatIntervalDays) : null,
                            occurEveryMode: occurEveryMode,
                            occurValue: (customOccurValue && !isNaN(parseInt(customOccurValue))) ? parseInt(customOccurValue) : null,
                            occurDays: customOccurDays,
                            occurDates: customOccurDates,
                        }).returning();

                        currentMasterId = newMaster.id;
                    }

                    await db.insert(checklist).values({
                        masterId: currentMasterId,
                        delegationId: newDelegation.id,
                        itemName: item.text || item.itemName || '',
                        assignerId: assignerId,
                        doerId: targetDoerId,
                        priority: priority,
                        category: category,
                        verificationRequired: evidenceRequired === true,
                        attachmentRequired: evidenceRequired === true,
                        frequency: isRepeat ? repeatFrequency : null,
                        status: 'Pending',
                        dueDate: dueDate ? new Date(dueDate).toISOString().split('T')[0] : null,
                    });
                }
            }

            // Notify the assigned doer
            await createNotification(
                targetDoerId,
                'New Task Delegated',
                `You have been assigned a new task: ${taskTitle}`,
                'delegation',
                newDelegation.id
            );
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
            dueDate: repeatEndDate ? new Date(repeatEndDate).toISOString().split('T')[0] : null,
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
                    dueDate: repeatEndDate ? new Date(repeatEndDate).toISOString().split('T')[0] : null,
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
                dueDate: repeatEndDate ? new Date(repeatEndDate).toISOString().split('T')[0] : null,
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
        const { doerId, assignerId, startDate, endDate, search, category } = req.query;
        let conditions = [];

        if (doerId) {
            conditions.push(eq(delegations.doerId, doerId));
        }

        if (assignerId) {
            conditions.push(eq(delegations.assignerId, assignerId));
        }

        if (category && category !== 'Category' && category !== 'undefined') {
            conditions.push(ilike(delegations.category, category));
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

        let query = db.select().from(delegations);
        if (conditions.length > 0) {
            query = query.where(and(...conditions));
        }

        const allDelegations = await query.orderBy(desc(delegations.createdAt));

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
        
        // Fetch checklist items — wrapped in try-catch in case table doesn't exist yet
        let formattedChecklist = [];
        try {
            const rawChecklist = await db.select().from(checklist).where(eq(checklist.delegationId, id));
            formattedChecklist = rawChecklist.map(c => ({
                id: c.id,
                text: c.itemName,
                status: c.status,
                dueDate: c.dueDate
            }));
        } catch (checklistErr) {
            console.warn('[getDelegationById] checklist table query failed (table may not exist yet):', checklistErr.message);
        }

        // Debug log
        console.log(`[getDelegationById] id=${id}, remarks=${remarks.length}, voice=${delegation.voiceNoteUrl}, docs=${delegation.referenceDocs}`);

        return reply.status(200).send({
            success: true,
            data: {
                ...delegation,
                revision_history: revisions,
                remarks: remarks,
                checklistItems: formattedChecklist
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

        const newDueDate = updates.dueDate ? new Date(updates.dueDate).toISOString().split('T')[0] : existingDelegation.dueDate;
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
            'referenceDocs', 'evidenceRequired', 'evidenceUrl', 'inLoopIds'
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
            .where(eq(delegations.id, id))
            .returning();

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

    try {
        // Cascade delete: Pehle related bacche rows (revisions, remarks, checklist) delete karo
        await db.delete(checklist).where(eq(checklist.delegationId, id)).catch(e => { /* Ignore if not exists */ });
        await db.delete(remarkHistory).where(eq(remarkHistory.delegationId, id));
        await db.delete(revisionHistory).where(eq(revisionHistory.delegationId, id));

        // Ab finally Task (delegation) delete karo
        const [deletedDelegation] = await db.delete(delegations).where(eq(delegations.id, id)).returning();

        if (!deletedDelegation) {
            return reply.status(404).send({
                success: false,
                message: 'Delegation not found'
            });
        }

        return reply.status(200).send({
            success: true,
            message: 'Delegation deleted successfully'
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

export const updateRemark = async (req, reply) => {
    const { id, remarkId } = req.params;
    const { remark } = req.body;
    try {
        const [updated] = await db.update(remarkHistory)
            .set({ remark })
            .where(eq(remarkHistory.id, remarkId))
            .returning();
        if (!updated) {
            return reply.status(404).send({ success: false, message: 'Remark not found' });
        }
        return reply.status(200).send({ success: true, message: 'Remark updated', data: updated });
    } catch (error) {
        req.log.error(error);
        return reply.status(500).send({ success: false, message: 'Failed to update remark', error: error.message });
    }
};

export const deleteRemark = async (req, reply) => {
    const { id, remarkId } = req.params;
    try {
        await db.delete(remarkHistory).where(eq(remarkHistory.id, remarkId));
        return reply.status(200).send({ success: true, message: 'Remark deleted' });
    } catch (error) {
        req.log.error(error);
        return reply.status(500).send({ success: false, message: 'Failed to delete remark', error: error.message });
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

export const toggleChecklistStatus = async (req, reply) => {
    const { delegationId, checklistId } = req.params;
    const { status } = req.body;

    try {
        const [updatedChecklist] = await db.update(checklist)
            .set({ status })
            .where(eq(checklist.id, checklistId))
            .returning();

        if (!updatedChecklist) {
            return reply.status(404).send({
                success: false,
                message: 'Checklist item not found'
            });
        }

        return reply.status(200).send({
            success: true,
            message: 'Checklist status updated',
            data: updatedChecklist
        });
    } catch (error) {
        req.log.error(error);
        return reply.status(500).send({
            success: false,
            message: 'Failed to update checklist status',
            error: error.message
        });
    }
};
