import { db } from '../db/index.js';
import { categories, delegations } from '../db/schema.js';
import { eq, desc, ilike } from 'drizzle-orm';

export const createCategory = async (req, reply) => {
    const { name, color, createdBy } = req.body;
    try {
        if (!name || !color) {
            return reply.code(400).send({ error: "Name and color are required" });
        }

        const [newCategory] = await db.insert(categories).values({
            name: name.trim(),
            color: color.trim(),
            createdBy: createdBy || null,
        }).returning();

        console.log('✅ Category created:', newCategory.name);
        return reply.code(201).send(newCategory);
    } catch (error) {
        console.error("❌ Error creating category:", error);
        return reply.code(500).send({ error: "Failed to create category" });
    }
};

export const getCategories = async (req, reply) => {
    try {
        const allCategories = await db.select()
            .from(categories)
            .orderBy(desc(categories.createdAt));
        
        // Add task count for each category
        const categoriesWithCount = await Promise.all(
            allCategories.map(async (cat) => {
                const taskCount = await db.select()
                    .from(delegations)
                    .where(eq(delegations.category, cat.name));
                return {
                    ...cat,
                    taskCount: taskCount.length
                };
            })
        );

        console.log('✅ Fetched', categoriesWithCount.length, 'categories');
        return reply.send(categoriesWithCount);
    } catch (error) {
        console.error("❌ Error fetching categories:", error);
        return reply.code(500).send({ error: "Failed to fetch categories" });
    }
};

export const getCategoryById = async (req, reply) => {
    const { id } = req.params;
    try {
        const [category] = await db.select()
            .from(categories)
            .where(eq(categories.id, id));

        if (!category) {
            return reply.code(404).send({ error: "Category not found" });
        }

        // Get task count
        const tasks = await db.select()
            .from(delegations)
            .where(eq(delegations.category, category.name));

        return reply.send({
            ...category,
            taskCount: tasks.length
        });
    } catch (error) {
        console.error("❌ Error fetching category:", error);
        return reply.code(500).send({ error: "Failed to fetch category" });
    }
};

export const updateCategory = async (req, reply) => {
    const { id } = req.params;
    const { name, color } = req.body;
    try {
        if (!name || !color) {
            return reply.code(400).send({ error: "Name and color are required" });
        }

        const [category] = await db.select()
            .from(categories)
            .where(eq(categories.id, id));

        if (!category) {
            return reply.code(404).send({ error: "Category not found" });
        }

        // If name changed, update all tasks with old category name
        if (category.name !== name) {
            await db.update(delegations)
                .set({ category: name.trim() })
                .where(eq(delegations.category, category.name));
        }

        const [updated] = await db.update(categories)
            .set({
                name: name.trim(),
                color: color.trim()
            })
            .where(eq(categories.id, id))
            .returning();

        console.log('✅ Category updated:', updated.name);
        return reply.send(updated);
    } catch (error) {
        console.error("❌ Error updating category:", error);
        return reply.code(500).send({ error: "Failed to update category" });
    }
};

export const deleteCategory = async (req, reply) => {
    const { id } = req.params;
    try {
        const [category] = await db.select()
            .from(categories)
            .where(eq(categories.id, id));

        if (!category) {
            return reply.code(404).send({ error: "Category not found" });
        }

        await db.delete(categories)
            .where(eq(categories.id, id));

        console.log('✅ Category deleted:', category.name);
        return reply.send({ message: `Category "${category.name}" deleted successfully` });
    } catch (error) {
        console.error("❌ Error deleting category:", error);
        return reply.code(500).send({ error: "Failed to delete category" });
    }
};

export const deleteCategoryTasks = async (req, reply) => {
    const { id } = req.params;
    try {
        const [category] = await db.select()
            .from(categories)
            .where(eq(categories.id, id));

        if (!category) {
            return reply.code(404).send({ error: "Category not found" });
        }

        // Delete all tasks in this category
        const result = await db.delete(delegations)
            .where(eq(delegations.category, category.name))
            .returning();

        console.log('✅ Deleted', result.length, 'tasks from category:', category.name);
        return reply.send({ 
            message: `Deleted ${result.length} tasks from category "${category.name}"`,
            deletedCount: result.length
        });
    } catch (error) {
        console.error("❌ Error deleting category tasks:", error);
        return reply.code(500).send({ error: "Failed to delete tasks" });
    }
};

export const removeCategoryLink = async (req, reply) => {
    const { id } = req.params;
    try {
        const [category] = await db.select()
            .from(categories)
            .where(eq(categories.id, id));

        if (!category) {
            return reply.code(404).send({ error: "Category not found" });
        }

        // Remove category from all tasks (set to null)
        const result = await db.update(delegations)
            .set({ category: null })
            .where(eq(delegations.category, category.name))
            .returning();

        console.log('✅ Removed category link from', result.length, 'tasks');
        return reply.send({ 
            message: `Removed category link from ${result.length} tasks`,
            unlinkedCount: result.length
        });
    } catch (error) {
        console.error("❌ Error removing category link:", error);
        return reply.code(500).send({ error: "Failed to remove category link" });
    }
};

export const searchCategories = async (req, reply) => {
    const { search = '' } = req.query;
    try {
        const results = await db.select()
            .from(categories)
            .where(ilike(categories.name, `%${search}%`))
            .orderBy(desc(categories.createdAt));

        return reply.send(results);
    } catch (error) {
        console.error("❌ Error searching categories:", error);
        return reply.code(500).send({ error: "Failed to search categories" });
    }
};
