import { db } from '../db/index.js';
import { exportLogs, delegations, users } from '../db/schema.js';
import { eq, and, gte, lte, inArray } from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';

// Create export
export const createExport = async (request, reply) => {
    try {
        const userId = request.user.id;
        const { dateRange, assignedTo, assignedBy, taskType } = request.body;

        // Generate export file (simplified - in production, you'd generate actual CSV/PDF)
        const exportId = uuidv4();
        const fileName = `tasks_export_${exportId}.csv`;
        
        // Calculate expiry date (60 days from now)
        const expiresAt = new Date();
        expiresAt.setDate(expiresAt.getDate() + 60);

        // Insert export log
        const result = await db.insert(exportLogs)
            .values({
                userId,
                dateRange,
                assignedTo: assignedTo || [],
                assignedBy: assignedBy || [],
                taskType: taskType || [],
                filePath: `/exports/${fileName}`,
                fileSize: 1024 * 50, // 50KB placeholder
                exportFormat: 'csv',
                createdAt: new Date(),
                expiresAt
            })
            .returning();

        return {
            message: 'Export created successfully',
            data: result[0]
        };
    } catch (error) {
        reply.status(500).send({ error: error.message });
    }
};

// Get export logs for current user
export const getExportLogs = async (request, reply) => {
    try {
        const userId = request.user.id;

        const logs = await db.query.exportLogs.findMany({
            where: eq(exportLogs.userId, userId),
            orderBy: (log) => log.createdAt,
        });

        // Enrich with user details
        const enrichedLogs = await Promise.all(logs.map(async (log) => {
            const exportedBy = await db.query.users.findFirst({
                where: eq(users.userId, log.userId)
            });

            return {
                ...log,
                exportedBy: exportedBy ? `${exportedBy.firstName} ${exportedBy.lastName}` : 'Unknown'
            };
        }));

        return {
            logs: enrichedLogs
        };
    } catch (error) {
        reply.status(500).send({ error: error.message });
    }
};

// Get all export logs (admin only)
export const getAllExportLogs = async (request, reply) => {
    try {
        const role = request.user.role?.toLowerCase();
        
        if (role !== 'admin') {
            return reply.status(403).send({ error: 'Permission denied' });
        }

        const logs = await db.query.exportLogs.findMany({
            orderBy: (log) => log.createdAt,
        });

        // Enrich with user details
        const enrichedLogs = await Promise.all(logs.map(async (log) => {
            const exportedByUser = await db.query.users.findFirst({
                where: eq(users.userId, log.userId)
            });

            return {
                ...log,
                exportedBy: exportedByUser ? `${exportedByUser.firstName} ${exportedByUser.lastName}` : 'Unknown'
            };
        }));

        return {
            logs: enrichedLogs
        };
    } catch (error) {
        reply.status(500).send({ error: error.message });
    }
};

// Download export file
export const downloadExport = async (request, reply) => {
    try {
        const { id } = request.params;
        const userId = request.user.id;

        const log = await db.query.exportLogs.findFirst({
            where: eq(exportLogs.id, id)
        });

        if (!log) {
            return reply.status(404).send({ error: 'Export not found' });
        }

        // Check if user owns this export or is admin
        const role = request.user.role?.toLowerCase();
        if (log.userId !== userId && role !== 'admin') {
            return reply.status(403).send({ error: 'Permission denied' });
        }

        // Check if export has expired
        if (new Date() > new Date(log.expiresAt)) {
            return reply.status(410).send({ error: 'Export has expired' });
        }

        // In production, you would serve the actual file
        return {
            message: 'Export file ready for download',
            data: {
                id: log.id,
                fileName: log.filePath.split('/').pop(),
                fileSize: log.fileSize,
                createdAt: log.createdAt
            }
        };
    } catch (error) {
        reply.status(500).send({ error: error.message });
    }
};

// Delete export log
export const deleteExport = async (request, reply) => {
    try {
        const { id } = request.params;
        const userId = request.user.id;
        const role = request.user.role?.toLowerCase();

        const log = await db.query.exportLogs.findFirst({
            where: eq(exportLogs.id, id)
        });

        if (!log) {
            return reply.status(404).send({ error: 'Export not found' });
        }

        // Check if user owns this export or is admin
        if (log.userId !== userId && role !== 'admin') {
            return reply.status(403).send({ error: 'Permission denied' });
        }

        await db.delete(exportLogs)
            .where(eq(exportLogs.id, id));

        return {
            message: 'Export deleted successfully'
        };
    } catch (error) {
        reply.status(500).send({ error: error.message });
    }
};
