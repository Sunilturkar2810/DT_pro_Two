import { createCategory, getCategories } from '../controllers/category.controller.js';

async function categoryRoutes(fastify, options) {
    fastify.post('/create', createCategory);
    fastify.get('/list', getCategories);
}

export default categoryRoutes;
