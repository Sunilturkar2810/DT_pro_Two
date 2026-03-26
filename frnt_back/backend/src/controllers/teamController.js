import { db } from '../db/index.js';
import { teams, teamMembers, users } from '../db/schema.js';
import { eq, and, inArray, or } from 'drizzle-orm';

export const createTeam = async (request, reply) => {
    const { name, description, members } = request.body;
    const currentUserId = request.user.id;

    try {
        // Only SUPERADMIN or ADMIN can create teams
        if (!['SUPERADMIN', 'ADMIN'].includes(request.user.role?.toUpperCase())) {
            return reply.code(403).send({ message: 'Only SUPERADMIN and ADMIN can create teams' });
        }

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
        const creatorInMembers = members && members.some(m => m.userId === currentUserId);
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
        // Find all teamIds where current user is a member
        const myTeams = await db.select({ teamId: teamMembers.teamId })
            .from(teamMembers)
            .where(eq(teamMembers.userId, currentUserId));

        const teamIds = myTeams.map(t => t.teamId);
console.log('Current User:', currentUserId);
console.log('My Teams:', myTeams);
console.log('Team IDs:', teamIds);
        // Get all members of those teams
        const members = await db.select({
            userId: users.userId,
            firstName: users.firstName,
            lastName: users.lastName,
            workEmail: users.workEmail,
            mobileNumber: users.mobileNumber,
            role: users.role,
            designation: users.designation,
            department: users.department,
            reportingManagerId: users.reportingManagerId,
            taskAccess: users.taskAccess,
            leaveAccess: users.leaveAccess,
            addedBy: teamMembers.addedBy,
            teamName: teams.name,
            teamId: teamMembers.teamId,
            status: users.status,
        })
        .from(teamMembers)
        .innerJoin(users, eq(teamMembers.userId, users.userId))
        .innerJoin(teams, eq(teamMembers.teamId, teams.teamId))
        .where(and(
            inArray(teamMembers.teamId, teamIds),
            eq(users.status, 'active')
        ));

        console.log('My Team Members:', members);
        return reply.send(members);
    } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ message: 'Internal Server Error' });
    }
};

export const removeTeamMember = async (request, reply) => {
    const { teamId, userId } = request.params;
    try {
        if (!['SUPERADMIN', 'ADMIN'].includes(request.user.role?.toUpperCase())) {
            return reply.code(403).send({ message: 'Only SUPERADMIN and ADMIN can remove team members' });
        }

        await db.delete(teamMembers)
            .where(and(
                eq(teamMembers.teamId, teamId),
                eq(teamMembers.userId, userId)
            ));

        return reply.send({ message: 'Member removed from team' });
    } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ message: 'Internal Server Error' });
    }
};
