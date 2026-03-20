import { holidayController } from '../controllers/holiday.controller.js';

export default async function holidayRoutes(fastify, options) {
    // All routes require authentication
    fastify.addHook('onRequest', fastify.authenticate);

    fastify.post('/', holidayController.createHoliday);
    fastify.get('/', holidayController.getHolidays);
    fastify.delete('/:id', holidayController.deleteHoliday);
}
