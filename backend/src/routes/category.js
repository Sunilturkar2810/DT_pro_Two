import { 
    createCategory, 
    getCategories, 
    getCategoryById, 
    updateCategory, 
    deleteCategory,
    deleteCategoryTasks,
    removeCategoryLink,
    searchCategories 
} from '../controllers/category.controller.js';

async function categoryRoutes(fastify, options) {
    // GET all categories with task count
    fastify.get('/', getCategories);
    fastify.get('/list', getCategories);
    
    // Search categories
    fastify.get('/search', searchCategories);
    
    // Create category
    fastify.post('/create', createCategory);
    
    // Get single category by ID
    fastify.get('/:id', getCategoryById);
    
    // Update category
    fastify.put('/:id', updateCategory);
    
    // Delete category
    fastify.delete('/:id', deleteCategory);
    
    // Delete all tasks in category
    fastify.delete('/:id/tasks', deleteCategoryTasks);
    
    // Remove category link from tasks (set category to null)
    fastify.delete('/:id/unlink', removeCategoryLink);
}

export default categoryRoutes;
