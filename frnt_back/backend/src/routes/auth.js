import { register, bulkRegister, login, getUsers, getMe, updateUser, updateCredentials, updatePassword, deleteAllTasks, deleteUser } from '../controllers/authController.js';
import { getRoles, createRole } from '../controllers/roleController.js';

export default async function authRoutes(fastify, options) {
    fastify.post('/register', {
        onRequest: [fastify.authenticate]
    }, register);
    fastify.post('/bulk-register', {
        onRequest: [fastify.authenticate]
    }, bulkRegister);
    fastify.post('/login', login);
    fastify.get('/me', {
        onRequest: [fastify.authenticate]
    }, getMe);
    fastify.get('/users', {
        onRequest: [async (request, reply) => {
            try {
                await request.jwtVerify();
            } catch (err) {
                reply.send(err);
            }
        }]
    }, getUsers);

    fastify.put('/users/:userId', {
        onRequest: [fastify.authenticate]
    }, updateUser);
    fastify.put('/users/:userId/credentials', {
        onRequest: [fastify.authenticate]
    }, updateCredentials);
    fastify.put('/update-password/:userId', {
        onRequest: [fastify.authenticate]
    }, updatePassword);
    fastify.delete('/users/:userId/tasks', {
        onRequest: [fastify.authenticate]
    }, deleteAllTasks);
    fastify.delete('/users/:userId', {
        onRequest: [fastify.authenticate]
    }, deleteUser);

    fastify.get('/roles', {
        onRequest: [fastify.authenticate]
    }, getRoles);
    fastify.post('/roles/create', {
        onRequest: [fastify.authenticate]
    }, createRole);
}
