import { db } from '../db/index.js';
import { roles, rolePermissions } from '../db/schema.js';
import { eq, and } from 'drizzle-orm';

const DEFAULT_ACTIONS = ['Create', 'Edit', 'View', 'Delete', 'Import Task', 'Export Task'];
const DEFAULT_ROLES = {
    Admin: {
        Create: true,
        Edit: true,
        View: true,
        Delete: true,
        'Import Task': true,
        'Export Task': true
    },
    Manager: {
        Create: true,
        Edit: true,
        View: true,
        Delete: false,
        'Import Task': true,
        'Export Task': true
    },
    'Team Member': {
        Create: true,
        Edit: false,
        View: true,
        Delete: false,
        'Import Task': false,
        'Export Task': false
    }
};

// Get all roles (default + custom) with their permissions
export const getAllRoles = async (request, reply) => {
    try {
        const allRoles = await db.query.roles.findMany();

        // Get detailed roles with permissions
        const rolesWithPermissions = await Promise.all(
            allRoles.map(async (role) => {
                const permissions = await db.query.rolePermissions.findMany({
                    where: eq(rolePermissions.roleId, role.id)
                });

                const permissionMap = {};
                permissions.forEach(perm => {
                    permissionMap[perm.action] = perm.allowed;
                });

                return {
                    ...role,
                    permissions: permissionMap
                };
            })
        );

        console.log(`✅ Returning ${rolesWithPermissions.length} roles`);
        return {
            roles: rolesWithPermissions
        };
    } catch (error) {
        console.error('❌ getAllRoles error:', error.message);
        reply.status(500).send({ error: error.message });
    }
};

// Get single role with permissions
export const getRoleWithPermissions = async (request, reply) => {
    try {
        const { id } = request.params;

        const role = await db.query.roles.findFirst({
            where: eq(roles.id, id)
        });

        if (!role) {
            return reply.status(404).send({ error: 'Role not found' });
        }

        const permissions = await db.query.rolePermissions.findMany({
            where: eq(rolePermissions.roleId, id)
        });

        const permissionMap = {};
        permissions.forEach(perm => {
            permissionMap[perm.action] = perm.allowed;
        });

        return {
            role: {
                ...role,
                permissions: permissionMap
            }
        };
    } catch (error) {
        reply.status(500).send({ error: error.message });
    }
};

// Create custom role
export const createRole = async (request, reply) => {
    try {
        const userId = request.user.id;
        const role = request.user.role?.toLowerCase();
        
        if (role !== 'admin') {
            return reply.status(403).send({ error: 'Only admins can create roles' });
        }

        const { name, description } = request.body;

        if (!name) {
            return reply.status(400).send({ error: 'Role name is required' });
        }

        // Check if role already exists
        const existing = await db.query.roles.findFirst({
            where: eq(roles.name, name)
        });

        if (existing) {
            return reply.status(409).send({ error: 'Role already exists' });
        }

        // Create role
        const result = await db.insert(roles)
            .values({
                name,
                description,
                isDefault: false,
                createdBy: userId,
                createdAt: new Date(),
                updatedAt: new Date()
            })
            .returning();

        const newRole = result[0];

        // Create default permissions (all false for new custom roles)
        for (const action of DEFAULT_ACTIONS) {
            await db.insert(rolePermissions)
                .values({
                    roleId: newRole.id,
                    action,
                    allowed: false,
                    createdAt: new Date(),
                    updatedAt: new Date()
                });
        }

        return {
            message: 'Role created successfully',
            data: newRole
        };
    } catch (error) {
        reply.status(500).send({ error: error.message });
    }
};

// Update role
export const updateRole = async (request, reply) => {
    try {
        const userId = request.user.id;
        const userRole = request.user.role?.toLowerCase();
        
        if (userRole !== 'admin') {
            return reply.status(403).send({ error: 'Only admins can update roles' });
        }

        const { id } = request.params;
        const { name, description } = request.body;

        const role = await db.query.roles.findFirst({
            where: eq(roles.id, id)
        });

        if (!role) {
            return reply.status(404).send({ error: 'Role not found' });
        }

        // Cannot modify default roles
        if (role.isDefault) {
            return reply.status(400).send({ error: 'Cannot modify default roles' });
        }

        const result = await db.update(roles)
            .set({
                name,
                description,
                updatedAt: new Date()
            })
            .where(eq(roles.id, id))
            .returning();

        return {
            message: 'Role updated successfully',
            data: result[0]
        };
    } catch (error) {
        reply.status(500).send({ error: error.message });
    }
};

// Delete role
export const deleteRole = async (request, reply) => {
    try {
        const userRole = request.user.role?.toLowerCase();
        
        if (userRole !== 'admin') {
            return reply.status(403).send({ error: 'Only admins can delete roles' });
        }

        const { id } = request.params;

        const role = await db.query.roles.findFirst({
            where: eq(roles.id, id)
        });

        if (!role) {
            return reply.status(404).send({ error: 'Role not found' });
        }

        // Cannot delete default roles
        if (role.isDefault) {
            return reply.status(400).send({ error: 'Cannot delete default roles' });
        }

        // Delete permissions first
        await db.delete(rolePermissions)
            .where(eq(rolePermissions.roleId, id));

        // Delete role
        await db.delete(roles)
            .where(eq(roles.id, id));

        return {
            message: 'Role deleted successfully'
        };
    } catch (error) {
        reply.status(500).send({ error: error.message });
    }
};

// Update role permissions
export const updateRolePermissions = async (request, reply) => {
    try {
        const userRole = request.user.role?.toLowerCase();
        
        if (userRole !== 'admin') {
            return reply.status(403).send({ error: 'Only admins can update permissions' });
        }

        const { id } = request.params;
        const { permissions } = request.body; // { action: boolean, ... }

        const role = await db.query.roles.findFirst({
            where: eq(roles.id, id)
        });

        if (!role) {
            return reply.status(404).send({ error: 'Role not found' });
        }

        // Update each permission
        for (const [action, allowed] of Object.entries(permissions)) {
            const existing = await db.query.rolePermissions.findFirst({
                where: and(
                    eq(rolePermissions.roleId, id),
                    eq(rolePermissions.action, action)
                )
            });

            if (existing) {
                await db.update(rolePermissions)
                    .set({
                        allowed,
                        updatedAt: new Date()
                    })
                    .where(and(
                        eq(rolePermissions.roleId, id),
                        eq(rolePermissions.action, action)
                    ));
            } else {
                await db.insert(rolePermissions)
                    .values({
                        roleId: id,
                        action,
                        allowed,
                        createdAt: new Date(),
                        updatedAt: new Date()
                    });
            }
        }

        // Fetch updated permissions
        const updatedPermissions = await db.query.rolePermissions.findMany({
            where: eq(rolePermissions.roleId, id)
        });

        const permissionMap = {};
        updatedPermissions.forEach(perm => {
            permissionMap[perm.action] = perm.allowed;
        });

        return {
            message: 'Permissions updated successfully',
            data: {
                roleId: id,
                permissions: permissionMap
            }
        };
    } catch (error) {
        reply.status(500).send({ error: error.message });
    }
};
