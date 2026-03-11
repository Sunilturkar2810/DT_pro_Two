import { createTeam, getTeams, getTeamMembers, getMyTeamMembers } from '../controllers/teamController.js';

export default async function teamRoutes(fastify, options) {
    fastify.addHook('onRequest', async (request, reply) => {
        try {
            await request.jwtVerify();
        } catch (err) {
            reply.send(err);
        }
    });

    fastify.post('/', createTeam);
    fastify.get('/', getTeams);
    fastify.get('/my-members', getMyTeamMembers);
    fastify.get('/:teamId/members', getTeamMembers);
}
