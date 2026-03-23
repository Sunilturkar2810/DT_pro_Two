import { getActivities } from '../controllers/activityController.js';

export default async function activityRoutes(fastify, options) {
    fastify.addHook('preHandler', fastify.authenticate);
    
    fastify.get('/', getActivities);
}
