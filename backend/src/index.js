import cluster from 'node:cluster';
import { availableParallelism } from 'node:os';
import process from 'node:process';
import buildApp from './app.js';
import dotenv from 'dotenv';
import { initCron } from './utils/cron.js';

dotenv.config();

const numCPUs = availableParallelism();
const PORT = process.env.PORT || 5000;

if (cluster.isPrimary) {
    console.log(`Primary ${process.pid} is running`);
 
    // Initialize cron jobs in primary process
    initCron();

    // Fork workers.
    for (let i = 0; i < numCPUs; i++) {
        cluster.fork();
    }

    cluster.on('exit', (worker, code, signal) => {
        console.log(`worker ${worker.process.pid} died. Starting a new worker...`);
        cluster.fork();
    });
} else {
    // Workers can share any TCP connection
    // In this case it is an HTTP server
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
            await app.listen({ port: PORT, host: '0.0.0.0' });
            console.log(`Worker ${process.pid} started on port ${PORT}`);
        } catch (err) {
            app.log.error(err);
            process.exit(1);
        }
    };

    start();
}
