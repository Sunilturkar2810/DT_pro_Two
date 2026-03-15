import * as rolesController from '../controllers/rolesController.js';

const rolesRoutes = async (app) => {
    // Get all roles with permissions
    app.get(
        '/',
        { onRequest: [app.authenticate] },
        rolesController.getAllRoles
    );

    // Get single role with permissions
    app.get(
        '/:id',
        { onRequest: [app.authenticate] },
        rolesController.getRoleWithPermissions
    );

    // Create custom role
    app.post(
        '/',
        { onRequest: [app.authenticate] },
        rolesController.createRole
    );

    // Update role
    app.put(
        '/:id',
        { onRequest: [app.authenticate] },
        rolesController.updateRole
    );

    // Delete role
    app.delete(
        '/:id',
        { onRequest: [app.authenticate] },
        rolesController.deleteRole
    );

    // Update role permissions
    app.put(
        '/:id/permissions',
        { onRequest: [app.authenticate] },
        rolesController.updateRolePermissions
    );
};

export default rolesRoutes;
