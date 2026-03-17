import { db } from '../db/index.js';
import { holidays } from '../db/schema.js';
import { eq } from 'drizzle-orm';

// Get all holidays
export const getHolidays = async (request, reply) => {
    try {
        const allHolidays = await db.query.holidays.findMany({
            orderBy: (holidays, { asc }) => [asc(holidays.date)]
        });
        
        return reply.send({
            success: true,
            holidays: allHolidays
        });
    } catch (error) {
        console.error('⚠️ getHolidays error:', error.message);
        return reply.status(500).send({ success: false, message: error.message });
    }
};

// Add a holiday
export const addHoliday = async (request, reply) => {
    try {
        const { name, date } = request.body;
        
        if (!name || !date) {
            return reply.status(400).send({ success: false, message: 'Name and date are required' });
        }

        const newHoliday = await db.insert(holidays).values({
            name,
            date,
            createdBy: request.user?.id
        }).returning();

        return reply.send({
            success: true,
            holiday: newHoliday[0],
            message: 'Holiday added successfully'
        });
    } catch (error) {
        console.error('⚠️ addHoliday error:', error.message);
        return reply.status(500).send({ success: false, message: error.message });
    }
};

// Delete a holiday
export const deleteHoliday = async (request, reply) => {
    try {
        const { id } = request.params;
        
        await db.delete(holidays).where(eq(holidays.id, id));
        
        return reply.send({
            success: true,
            message: 'Holiday deleted successfully'
        });
    } catch (error) {
        console.error('⚠️ deleteHoliday error:', error.message);
        return reply.status(500).send({ success: false, message: error.message });
    }
};
