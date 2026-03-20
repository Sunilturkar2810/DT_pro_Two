import { createCategory, getCategories, deleteCategory } from '../controllers/category.controller.js';

async function categoryRoutes(fastify, options) {
    fastify.post('/create', createCategory);
    fastify.get('/list', getCategories);
    fastify.delete('/:id', deleteCategory);
}

export default categoryRoutes;
