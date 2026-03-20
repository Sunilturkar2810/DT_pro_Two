import { getNotificationSettings, updateNotificationSettings } from '../controllers/notificationPreference.controller.js';

export default async function (fastify, opts) {
    fastify.addHook('preHandler', fastify.authenticate);

    fastify.get('/', getNotificationSettings);
    fastify.post('/', updateNotificationSettings);
}
