import { db } from '../db/index.js';
import { teams, teamMembers, users } from '../db/schema.js';
import { eq, and, inArray } from 'drizzle-orm';

export const createTeam = async (request, reply) => {
    const { name, description, members } = request.body;
    const currentUserId = request.user.id;

    try {
        // Only SuperAdmin or Admin can create teams
        if (request.user.role !== 'SUPERADMIN' && request.user.role !== 'ADMIN') {
            return reply.code(403).send({ message: 'Only SuperAdmin and Admin can create teams' });
        }

        // Create the team
        const newTeam = await db.insert(teams).values({
            name,
            description,
            createdBy: currentUserId,
        }).returning();

        const teamId = newTeam[0].teamId;

        // Add members if provided
        if (members && members.length > 0) {
            const memberValues = members.map(member => ({
                teamId,
                userId: member.userId,
                role: member.role || 'Team Member',
                reportsTo: member.reportsTo,
                addedBy: currentUserId,
            }));

            await db.insert(teamMembers).values(memberValues);
        }

        return reply.code(201).send({
            message: 'Team created successfully',
            team: newTeam[0],
        });
    } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ message: 'Internal Server Error' });
    }
};

export const getTeams = async (request, reply) => {
    try {
        const allTeams = await db.select().from(teams);
        return reply.send(allTeams);
    } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ message: 'Internal Server Error' });
    }
};

export const getTeamMembers = async (request, reply) => {
    const { teamId } = request.params;

    try {
        const members = await db.select({
            id: teamMembers.id,
            role: teamMembers.role,
            userName: users.firstName,
            userLastName: users.lastName,
            email: users.workEmail,
            reportsTo: teamMembers.reportsTo,
        })
            .from(teamMembers)
            .innerJoin(users, eq(teamMembers.userId, users.userId))
            .where(eq(teamMembers.teamId, teamId));

        return reply.send(members);
    } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ message: 'Internal Server Error' });
    }
};

export const getMyTeamMembers = async (request, reply) => {
    const currentUserId = request.user.id;

    try {
        // Find teams where the user is a member OR the user created the team
        const myTeamIdsParams = await db.select({ teamId: teamMembers.teamId })
            .from(teamMembers)
            .where(eq(teamMembers.userId, currentUserId));

        const createdTeamIdsParams = await db.select({ teamId: teams.teamId })
            .from(teams)
            .where(eq(teams.createdBy, currentUserId));

        const myTeamIds = myTeamIdsParams.map(t => t.teamId);
        const createdTeamIds = createdTeamIdsParams.map(t => t.teamId);

        // Combine and deduplicate team IDs
        const combinedTeamIds = [...new Set([...myTeamIds, ...createdTeamIds])];

        if (combinedTeamIds.length === 0) {
            return reply.send([]); // User is not in any team
        }

        // Fetch all members of these teams, resolving the 'reportsTo' user
        const memberResult = await db.select({
            userId: teamMembers.userId,
            teamId: teamMembers.teamId,
            role: teamMembers.role,
            firstName: users.firstName,
            lastName: users.lastName,
            workEmail: users.workEmail,
            mobileNumber: users.mobileNumber,
            managerId: teamMembers.reportsTo,
        })
            .from(teamMembers)
            .innerJoin(users, eq(teamMembers.userId, users.userId))
            .where(inArray(teamMembers.teamId, combinedTeamIds));

        const allUserIdsInTeams = [...new Set(memberResult.map(m => m.managerId).filter(Boolean))];
        let managerNames = {};

        if (allUserIdsInTeams.length > 0) {
            const managers = await db.select({
                userId: users.userId,
                firstName: users.firstName,
                lastName: users.lastName,
            })
                .from(users)
                .where(inArray(users.userId, allUserIdsInTeams));

            managerNames = managers.reduce((acc, current) => {
                acc[current.userId] = `${current.firstName} ${current.lastName}`;
                return acc;
            }, {});
        }

        // Deduplicate and format output
        const uniqueMembersMap = new Map();

        memberResult.forEach(member => {
            if (!uniqueMembersMap.has(member.userId)) {
                uniqueMembersMap.set(member.userId, {
                    userId: member.userId,
                    firstName: member.firstName,
                    lastName: member.lastName,
                    workEmail: member.workEmail,
                    mobileNumber: member.mobileNumber,
                    role: member.role, // If they are in multiple teams, this just takes the first found role
                    manager: member.managerId ? managerNames[member.managerId] || null : null,
                });
            }
        });

        const formattedMembers = Array.from(uniqueMembersMap.values());

        return reply.send(formattedMembers);

    } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ message: 'Internal Server Error' });
    }
};
