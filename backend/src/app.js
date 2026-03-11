import Fastify from 'fastify';
import fastifyJwt from '@fastify/jwt';
import fastifyCors from '@fastify/cors';
import fastifyMultipart from '@fastify/multipart';
import authRoutes from './routes/auth.js';
import delegationRoutes from './routes/delegation.js';
import teamRoutes from './routes/team.js';
import notificationRoutes from './routes/notifications.js';
import categoryRoutes from './routes/category.js';
import groupRoutes from './routes/group.js';
import dashboardRoutes from './routes/dashboard.js';
import dotenv from 'dotenv';

dotenv.config();

const buildApp = (options = {}) => {
    const app = Fastify(options);

    // Register plugins
    app.register(fastifyCors, {
        origin: '*', // Adjust for production
        methods: ['GET', 'PUT', 'POST', 'DELETE', 'PATCH', 'OPTIONS'],
    });

    app.register(fastifyMultipart, {
        limits: {
            fileSize: 10 * 1024 * 1024, // 10MB limit
        }
    });

    app.register(fastifyJwt, {
        secret: process.env.JWT_SECRET || 'fallback_secret_keep_it_safe',
    });

    app.decorate('authenticate', async (request, reply) => {
        try {
            await request.jwtVerify();
        } catch (err) {
            reply.send(err);
        }
    });

    // Health check
    app.get('/health', async () => {
        return { status: 'ok', timestamp: new Date().toISOString() };
    });

    // Register routes
    app.register(authRoutes, { prefix: '/api/auth' });
    app.register(delegationRoutes, { prefix: '/api/delegations' });
    app.register(teamRoutes, { prefix: '/api/teams' });
    app.register(notificationRoutes, { prefix: '/api/notifications' });
    app.register(categoryRoutes, { prefix: '/api/categories' });
    app.register(groupRoutes, { prefix: '/api/groups' });
    app.register(dashboardRoutes, { prefix: '/api/dashboard' });

    // Custom Error Handler
    app.setErrorHandler((error, request, reply) => {
        request.log.error(error);
        const statusCode = error.statusCode || 500;
        reply.status(statusCode).send({
            error: error.name,
            message: error.message || 'Something went wrong',
        });
    });

    return app;
};

export default buildApp;
