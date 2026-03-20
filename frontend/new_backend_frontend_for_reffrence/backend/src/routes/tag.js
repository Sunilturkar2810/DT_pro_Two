import { createTag, getTags, deleteTag } from '../controllers/tag.controller.js';

async function tagRoutes(fastify, options) {
    fastify.get('/list', getTags);
    fastify.post('/create', createTag);
    fastify.delete('/:id', deleteTag);
}

export default tagRoutes;
