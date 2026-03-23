import { getTemplates, getTemplateByEventAndChannel, saveTemplate, deleteTemplate } from '../controllers/notificationTemplate.controller.js';

export default async function (fastify, opts) {
    fastify.get('/', getTemplates);
    fastify.get('/:eventName/:channel', getTemplateByEventAndChannel);
    fastify.post('/', saveTemplate);
    fastify.delete('/:id', deleteTemplate);
}
