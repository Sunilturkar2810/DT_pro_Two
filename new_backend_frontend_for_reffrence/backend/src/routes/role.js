import { getRoles, createRole, updateRole, deleteRole } from '../controllers/roleController.js';

export default async function roleRoutes(fastify, options) {
    fastify.get('/', { onRequest: [fastify.authenticate] }, getRoles);
    fastify.post('/', { onRequest: [fastify.authenticate] }, createRole);
    fastify.put('/:id', { onRequest: [fastify.authenticate] }, updateRole);
    fastify.delete('/:id', { onRequest: [fastify.authenticate] }, deleteRole);
}
