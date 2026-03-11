import { getNotifications, markAsRead, markAllAsRead, deleteNotification, clearAll } from '../controllers/notification.controller.js';

export default async function (fastify, opts) {
    fastify.addHook('preHandler', fastify.authenticate);

    fastify.get('/', getNotifications);
    fastify.put('/:id/read', markAsRead);
    fastify.put('/read-all', markAllAsRead);
    fastify.delete('/:id', deleteNotification);
    fastify.delete('/clear-all', clearAll);
}
