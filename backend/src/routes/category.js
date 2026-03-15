import { createCategory, getCategories } from '../controllers/category.controller.js';

async function categoryRoutes(fastify, options) {
    fastify.get('/', getCategories);
    fastify.get('/list', getCategories);
    fastify.post('/create', createCategory);
}

export default categoryRoutes;
