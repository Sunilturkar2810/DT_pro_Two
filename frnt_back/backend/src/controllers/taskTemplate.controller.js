import { db } from '../db/index.js';
import { taskTemplates, users } from '../db/schema.js';
import { eq, desc } from 'drizzle-orm';

export const createTaskTemplate = async (req, reply) => {
    const { title, description, category, priority, frequency, checklistItems, createdBy } = req.body;
    try {
        const [template] = await db.insert(taskTemplates).values({
            title,
            description,
            category,
            priority,
            frequency: frequency || 'Once',
            checklistItems,
            createdBy,
            createdAt: new Date(),
            updatedAt: new Date(),
        }).returning();
        return reply.code(201).send({ success: true, data: template });
    } catch (err) {
        console.error('Error creating task template:', err);
        return reply.code(500).send({ success: false, message: 'Internal Server Error' });
    }
};

export const getTaskTemplates = async (req, reply) => {
    try {
        const templates = await db.select({
            id: taskTemplates.id,
            title: taskTemplates.title,
            description: taskTemplates.description,
            category: taskTemplates.category,
            priority: taskTemplates.priority,
            frequency: taskTemplates.frequency,
            checklistItems: taskTemplates.checklistItems,
            createdBy: taskTemplates.createdBy,
            createdAt: taskTemplates.createdAt,
            updatedAt: taskTemplates.updatedAt,
            creatorFirstName: users.firstName,
            creatorLastName: users.lastName
        })
        .from(taskTemplates)
        .leftJoin(users, eq(taskTemplates.createdBy, users.userId))
        .orderBy(desc(taskTemplates.createdAt));
        
        return reply.send({ success: true, data: templates });
    } catch (err) {
        console.error('Error fetching task templates:', err);
        return reply.code(500).send({ success: false, message: 'Internal Server Error' });
    }
};

export const updateTaskTemplate = async (req, reply) => {
    const { id } = req.params;
    const updates = req.body;
    try {
        const [updated] = await db.update(taskTemplates)
            .set({ ...updates, updatedAt: new Date() })
            .where(eq(taskTemplates.id, id))
            .returning();
        if (!updated) return reply.code(404).send({ success: false, message: 'Template not found' });
        return reply.send({ success: true, data: updated });
    } catch (err) {
        console.error('Error updating task template:', err);
        return reply.code(500).send({ success: false, message: 'Internal Server Error' });
    }
};

export const deleteTaskTemplate = async (req, reply) => {
    const { id } = req.params;
    try {
        const [deleted] = await db.delete(taskTemplates)
            .where(eq(taskTemplates.id, id))
            .returning();
        if (!deleted) return reply.code(404).send({ success: false, message: 'Template not found' });
        return reply.send({ success: true, message: 'Template deleted' });
    } catch (err) {
        console.error('Error deleting task template:', err);
        return reply.code(500).send({ success: false, message: 'Internal Server Error' });
    }
};
