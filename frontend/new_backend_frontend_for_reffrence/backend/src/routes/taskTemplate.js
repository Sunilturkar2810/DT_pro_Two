import { createTaskTemplate, getTaskTemplates, updateTaskTemplate, deleteTaskTemplate } from '../controllers/taskTemplate.controller.js';

export default async function taskTemplateRoutes(fastify, options) {
    fastify.post('/', { preValidation: [fastify.authenticate] }, createTaskTemplate);
    fastify.get('/', { preValidation: [fastify.authenticate] }, getTaskTemplates);
    fastify.put('/:id', { preValidation: [fastify.authenticate] }, updateTaskTemplate);
    fastify.delete('/:id', { preValidation: [fastify.authenticate] }, deleteTaskTemplate);
}
