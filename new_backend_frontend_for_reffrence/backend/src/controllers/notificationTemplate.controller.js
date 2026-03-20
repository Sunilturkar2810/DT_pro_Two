import { db } from '../db/index.js';
import { notificationTemplates } from '../db/schema.js';
import { eq, and } from 'drizzle-orm';

export const getTemplates = async (req, reply) => {
    try {
        const templates = await db.select().from(notificationTemplates);
        return reply.status(200).send({
            success: true,
            data: templates
        });
    } catch (error) {
        req.log.error(error);
        return reply.status(500).send({
            success: false,
            message: 'Failed to fetch notification templates'
        });
    }
};

export const getTemplateByEventAndChannel = async (req, reply) => {
    try {
        const { eventName, channel } = req.params;
        const [template] = await db.select()
            .from(notificationTemplates)
            .where(and(
                eq(notificationTemplates.eventName, eventName),
                eq(notificationTemplates.channel, channel)
            ))
            .limit(1);

        return reply.status(200).send({
            success: true,
            data: template || null
        });
    } catch (error) {
        req.log.error(error);
        return reply.status(500).send({
            success: false,
            message: 'Failed to fetch template'
        });
    }
};

export const saveTemplate = async (req, reply) => {
    try {
        const { eventName, channel, subject, body, isActive } = req.body;

        if (!eventName || !channel || !body) {
            return reply.status(400).send({
                success: false,
                message: 'Event name, channel, and body are required'
            });
        }

        const existing = await db.select()
            .from(notificationTemplates)
            .where(and(
                eq(notificationTemplates.eventName, eventName),
                eq(notificationTemplates.channel, channel)
            ))
            .limit(1);

        if (existing.length > 0) {
            const [updated] = await db.update(notificationTemplates)
                .set({
                    subject,
                    body,
                    isActive: isActive !== undefined ? isActive : true,
                    updatedAt: new Date()
                })
                .where(eq(notificationTemplates.id, existing[0].id))
                .returning();

            return reply.status(200).send({
                success: true,
                message: 'Template updated successfully',
                data: updated
            });
        } else {
            const [created] = await db.insert(notificationTemplates)
                .values({
                    eventName,
                    channel,
                    subject,
                    body,
                    isActive: isActive !== undefined ? isActive : true,
                    updatedAt: new Date()
                })
                .returning();

            return reply.status(201).send({
                success: true,
                message: 'Template created successfully',
                data: created
            });
        }
    } catch (error) {
        req.log.error(error);
        return reply.status(500).send({
            success: false,
            message: 'Failed to save template'
        });
    }
};

export const deleteTemplate = async (req, reply) => {
    try {
        const { id } = req.params;
        await db.delete(notificationTemplates).where(eq(notificationTemplates.id, id));
        return reply.status(200).send({
            success: true,
            message: 'Template deleted successfully'
        });
    } catch (error) {
        req.log.error(error);
        return reply.status(500).send({
            success: false,
            message: 'Failed to delete template'
        });
    }
};
