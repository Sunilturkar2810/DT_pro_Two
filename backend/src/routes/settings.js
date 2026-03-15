import * as settingsController from '../controllers/settingsController.js';

const settingsRoutes = async (app) => {
    // General Settings
    app.get(
        '/general',
        { onRequest: [app.authenticate] },
        settingsController.getGeneralSettings
    );

    app.post(
        '/general',
        { onRequest: [app.authenticate] },
        settingsController.updateGeneralSettings
    );

    // Task Update Settings
    app.get(
        '/task-update',
        { onRequest: [app.authenticate] },
        settingsController.getTaskUpdateSettings
    );

    app.post(
        '/task-update',
        { onRequest: [app.authenticate] },
        settingsController.updateTaskUpdateSettings
    );

    // Notification Settings
    app.get(
        '/notifications',
        { onRequest: [app.authenticate] },
        settingsController.getNotificationSettings
    );

    app.post(
        '/notifications',
        { onRequest: [app.authenticate] },
        settingsController.updateNotificationSettings
    );
};

export default settingsRoutes;
