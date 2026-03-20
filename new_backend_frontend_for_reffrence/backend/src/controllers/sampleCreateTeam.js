// Sample Fastify endpoint for creating a team and adding members
import { db } from '../db/index.js';
import { teams, teamMembers, users } from '../db/schema.js';

export const createTeamAndMembers = async (request, reply) => {
    const { name, description, members } = request.body;
    const currentUserId = request.user.id;

    try {
        // Create the team
        const newTeam = await db.insert(teams).values({
            name,
            description,
            createdBy: currentUserId,
        }).returning();

        const teamId = newTeam[0].teamId;

        // Add members
        if (members && members.length > 0) {
            const memberValues = members.map(member => ({
                teamId,
                userId: member.userId,
                role: member.role || 'TEAM MEMBER',
                reportsTo: member.reportsTo || null,
                addedBy: currentUserId,
            }));
            await db.insert(teamMembers).values(memberValues);
        }

        // Optionally, add creator as a member if not in members
        const creatorInMembers = members.some(m => m.userId === currentUserId);
        if (!creatorInMembers) {
            await db.insert(teamMembers).values({
                teamId,
                userId: currentUserId,
                role: 'ADMIN',
                reportsTo: null,
                addedBy: currentUserId,
            });
        }

        return reply.code(201).send({
            message: 'Team and members created',
            team: newTeam[0],
        });
    } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ message: 'Internal Server Error' });
    }
};

// Register this endpoint in your routes:
// fastify.post('/teams', createTeamAndMembers);
