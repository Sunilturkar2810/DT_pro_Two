import { db } from '../db/index.js';
import { holidays } from '../db/schema.js';
import { eq, desc } from 'drizzle-orm';

export const holidayController = {
    // Create a new holiday
    createHoliday: async (request, reply) => {
        try {
            const { name, date } = request.body;
            const userId = request.user.id;
            const role = request.user.role?.toUpperCase();

            if (role !== 'SUPERADMIN' && role !== 'ADMIN') {
                return reply.code(403).send({ message: 'Forbidden. Only Admins can add holidays.' });
            }

            if (!name || !date) {
                return reply.code(400).send({ message: 'Name and date are required' });
            }

            const [newHoliday] = await db
                .insert(holidays)
                .values({
                    name,
                    date,
                    createdBy: userId,
                })
                .returning();

            reply.code(201).send(newHoliday);
        } catch (error) {
            request.log.error(error);
            reply.code(500).send({ message: 'Failed to create holiday', error: error.message });
        }
    },

    // Get all holidays
    getHolidays: async (request, reply) => {
        try {
            const allHolidays = await db
                .select()
                .from(holidays)
                .orderBy(desc(holidays.date));

            reply.send(allHolidays);
        } catch (error) {
            request.log.error(error);
            reply.code(500).send({ message: 'Failed to fetch holidays', error: error.message });
        }
    },

    // Delete a holiday
    deleteHoliday: async (request, reply) => {
        try {
            const { id } = request.params;
            const role = request.user.role?.toUpperCase();

            if (role !== 'SUPERADMIN' && role !== 'ADMIN') {
                return reply.code(403).send({ message: 'Forbidden. Only Admins can delete holidays.' });
            }

            const [deletedHoliday] = await db
                .delete(holidays)
                .where(eq(holidays.id, id))
                .returning();

            if (!deletedHoliday) {
                return reply.code(404).send({ message: 'Holiday not found' });
            }

            reply.send({ message: 'Holiday deleted successfully' });
        } catch (error) {
            request.log.error(error);
            reply.code(500).send({ message: 'Failed to delete holiday', error: error.message });
        }
    }
};
