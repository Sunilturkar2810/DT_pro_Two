import * as exportController from '../controllers/exportController.js';

const exportRoutes = async (app) => {
    // Create export
    app.post(
        '/',
        { onRequest: [app.authenticate] },
        exportController.createExport
    );

    // Get export logs (user's own logs)
    app.get(
        '/logs',
        { onRequest: [app.authenticate] },
        exportController.getExportLogs
    );

    // Get all export logs (admin only)
    app.get(
        '/admin/logs',
        { onRequest: [app.authenticate] },
        exportController.getAllExportLogs
    );

    // Download export file
    app.get(
        '/:id/download',
        { onRequest: [app.authenticate] },
        exportController.downloadExport
    );

    // Delete export log
    app.delete(
        '/:id',
        { onRequest: [app.authenticate] },
        exportController.deleteExport
    );
};

export default exportRoutes;
