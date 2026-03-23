import { db } from '../db/index.js';
import { tags } from '../db/schema.js';
import { eq, desc } from 'drizzle-orm';

export const createTag = async (req, reply) => {
    const { name, color, createdBy } = req.body;
    try {
        const [newTag] = await db.insert(tags).values({
            name,
            color,
            createdBy: createdBy || null,
        }).returning();
        return reply.code(201).send(newTag);
    } catch (error) {
        console.error("Error creating tag:", error);
        return reply.code(500).send({ error: "Failed to create tag" });
    }
};

export const getTags = async (req, reply) => {
    try {
        const allTags = await db.select()
            .from(tags)
            .orderBy(desc(tags.createdAt));
        return reply.send(allTags);
    } catch (error) {
        console.error("Error fetching tags:", error);
        return reply.code(500).send({ error: "Failed to fetch tags" });
    }
};

export const deleteTag = async (req, reply) => {
    const { id } = req.params;
    try {
        await db.delete(tags).where(eq(tags.id, id));
        return reply.send({ success: true, message: "Tag deleted successfully" });
    } catch (error) {
        console.error("Error deleting tag:", error);
        return reply.code(500).send({ error: "Failed to delete tag" });
    }
};
