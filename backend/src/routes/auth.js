import { register, bulkRegister, login, getUsers, getMe, forgotPassword, resetPassword, deleteUser, updateProfile } from '../controllers/authController.js';
import { getMyTeamMembers } from '../controllers/teamController.js';

export default async function authRoutes(fastify, options) {
    fastify.post('/register', register);
    fastify.post('/bulk-register', {
        onRequest: [fastify.authenticate]
    }, bulkRegister);
    fastify.post('/login', login);
    fastify.post('/forgot-password', forgotPassword);
    fastify.post('/reset-password', resetPassword);
    
    fastify.put('/profile', {
        onRequest: [fastify.authenticate]
    }, updateProfile);

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
    fastify.delete('/users/:id', {
        onRequest: [async (request, reply) => {
            try {
                await request.jwtVerify();
            } catch (err) {
                reply.send(err);
            }
        }]
    }, deleteUser);
    fastify.get('/my-team', {
        onRequest: [async (request, reply) => {
            try {
                await request.jwtVerify();
            } catch (err) {
                reply.send(err);
            }
        }]
    }, getMyTeamMembers);
}
