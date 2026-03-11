import { db } from '../db/index.js';
import { categories } from '../db/schema.js';
import { eq, desc } from 'drizzle-orm';

export const createCategory = async (req, reply) => {
    const { name, color, createdBy } = req.body;
    try {
        const [newCategory] = await db.insert(categories).values({
            name,
            color,
            createdBy: createdBy || null,
        }).returning();
        return reply.code(201).send(newCategory);
    } catch (error) {
        console.error("Error creating category:", error);
        return reply.code(500).send({ error: "Failed to create category" });
    }
};

export const getCategories = async (req, reply) => {
    try {
        const allCategories = await db.select()
            .from(categories)
            .orderBy(desc(categories.createdAt));
        return reply.send(allCategories);
    } catch (error) {
        console.error("Error fetching categories:", error);
        return reply.code(500).send({ error: "Failed to fetch categories" });
    }
};
