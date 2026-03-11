import { getDashboardStats } from '../controllers/dashboardController.js';

export default async function dashboardRoutes(fastify, options) {
    fastify.get('/stats', {
        onRequest: [fastify.authenticate]
    }, getDashboardStats);
}
