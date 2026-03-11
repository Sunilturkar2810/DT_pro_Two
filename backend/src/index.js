import buildApp from './app.js';
import dotenv from 'dotenv';
import { initCron } from './utils/cron.js';

dotenv.config();

const PORT = process.env.PORT || 5000;

const app = buildApp({
    logger: {
        level: 'info',
        transport: {
            target: 'pino-pretty'
        }
    }
});

const start = async () => {
    try {
        // Initialize cron jobs
        initCron();

        // Start server
        await app.listen({ port: Number(PORT), host: '0.0.0.0' });
        console.log(`Server started on port ${PORT}`);
    } catch (err) {
        app.log.error(err);
        process.exit(1);
    }
};

start();
