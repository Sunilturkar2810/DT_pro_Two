import * as holidaysController from '../controllers/holidaysController.js';

const holidaysRoutes = async (app) => {
    // Get all holidays
    app.get(
        '/',
        { onRequest: [app.authenticate] },
        holidaysController.getHolidays
    );

    // Add a new holiday
    app.post(
        '/',
        { onRequest: [app.authenticate] },
        holidaysController.addHoliday
    );

    // Delete a holiday
    app.delete(
        '/:id',
        { onRequest: [app.authenticate] },
        holidaysController.deleteHoliday
    );
};

export default holidaysRoutes;
