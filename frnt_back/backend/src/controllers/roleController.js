import { db } from '../db/index.js';
import { roles } from '../db/schema.js';
import { eq } from 'drizzle-orm';

const defaultPermissions = {
    ADMIN: {
        taskTemplate: { create: true, edit: true, view: true, delete: true },
        task: { create: true, edit: 'All', delete: 'All', importTask: true, exportTask: 'All' },
        myTeam: { add: true, edit: 'All', delete: 'All', view: 'All' },
        holidays: { create: true, edit: true, view: true, delete: true },
        groups: { create: true, edit: true, view: true, delete: true },
        activity: { view: true },
        ideaBoard: { view: true },
        taskDirectory: { view: true }
    },
    MANAGER: {
        taskTemplate: { create: true, edit: true, view: true, delete: true },
        task: { create: true, edit: 'My Team + Assigned', delete: 'Assigned', importTask: true, exportTask: 'My Team + Me' },
        myTeam: { add: false, edit: 'My Team', delete: 'None', view: 'All' },
        holidays: { create: false, edit: false, view: true, delete: false },
        groups: { create: true, edit: true, view: true, delete: false },
        activity: { view: true },
        ideaBoard: { view: true },
        taskDirectory: { view: true }
    },
    'TEAM MEMBER': {
        taskTemplate: { create: true, edit: true, view: true, delete: true },
        task: { create: true, edit: 'Assigned', delete: 'Assigned', importTask: false, exportTask: 'None' },
        myTeam: { add: false, edit: 'None', delete: 'None', view: 'All' },
        holidays: { create: false, edit: false, view: true, delete: false },
        groups: { create: false, edit: false, view: true, delete: false },
        activity: { view: false },
        ideaBoard: { view: false },
        taskDirectory: { view: false }
    }
};

export const getRoles = async (request, reply) => {
    try {
        let allRoles = await db.select().from(roles);
        
        // Seed default roles if none exist
        if (allRoles.length === 0) {
            const defaultRolesToInsert = [
                { name: 'ADMIN', isCustom: false, description: 'Has full system access and permissions.', permissions: defaultPermissions['ADMIN'] },
                { name: 'MANAGER', isCustom: false, description: 'Can manage their team and team tasks.', permissions: defaultPermissions['MANAGER'] },
                { name: 'TEAM MEMBER', isCustom: false, description: 'Can manage their assigned tasks.', permissions: defaultPermissions['TEAM MEMBER'] }
            ];
            await db.insert(roles).values(defaultRolesToInsert);
            allRoles = await db.select().from(roles);
        }
        
        return reply.send(allRoles);
    } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ message: 'Internal Server Error' });
    }
};

export const createRole = async (request, reply) => {
    const { name, description, permissions } = request.body;
    const currentUserId = request.user.id;

    try {
        const existingRole = await db.query.roles.findFirst({
            where: eq(roles.name, name)
        });

        if (existingRole) {
            return reply.code(400).send({ message: `Role '${name}' already exists` });
        }

        const newRole = await db.insert(roles).values({
            name,
            description,
            permissions,
            isCustom: true,
            createdBy: currentUserId
        }).returning();

        return reply.code(201).send(newRole[0]);
    } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ message: 'Internal Server Error' });
    }
};

export const updateRole = async (request, reply) => {
    const { id } = request.params;
    const { name, description, permissions } = request.body;

    try {
        const existingRole = await db.query.roles.findFirst({
            where: eq(roles.id, id)
        });

        if (!existingRole) {
            return reply.code(404).send({ message: 'Role not found' });
        }
        
        if (!existingRole.isCustom && name && name !== existingRole.name) {
            return reply.code(400).send({ message: 'Cannot rename default roles' });
        }

        const updatedRole = await db.update(roles).set({
            name: name || existingRole.name,
            description: description !== undefined ? description : existingRole.description,
            permissions: permissions || existingRole.permissions,
        }).where(eq(roles.id, id)).returning();

        return reply.send(updatedRole[0]);
    } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ message: 'Internal Server Error' });
    }
};

export const deleteRole = async (request, reply) => {
    const { id } = request.params;

    try {
        const existingRole = await db.query.roles.findFirst({
            where: eq(roles.id, id)
        });

        if (!existingRole) {
            return reply.code(404).send({ message: 'Role not found' });
        }

        if (!existingRole.isCustom) {
            return reply.code(400).send({ message: 'Cannot delete default roles' });
        }

        await db.delete(roles).where(eq(roles.id, id));

        return reply.send({ message: 'Role deleted successfully' });
    } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ message: 'Internal Server Error' });
    }
};
