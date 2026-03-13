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
            designation: users.designation,
            department: users.department,
            profilePhotoUrl: users.profilePhotoUrl,
            personalEmail: users.personalEmail,
            emergencyMobileNo: users.emergencyMobileNo,
            dateOfBirth: users.dateOfBirth,
            maritalStatus: users.maritalStatus,
            gender: users.gender,
            address: users.address,
            city: users.city,
            state: users.state,
            nationality: users.nationality,
            joiningDate: users.joiningDate,
            currentSalary: users.currentSalary,
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
                // Find all fields for this user from the DB result
                const userRow = memberResult.find(m => m.userId === member.userId);
                
                // Fetch the full user object (excluding sensitive info if needed, but here we already selected specific fields)
                // Actually, let's just make the select above better.
                uniqueMembersMap.set(member.userId, {
                    ...member,
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

export const updateTeamMember = async (request, reply) => {
    try {
        const currentUserId = request.user.id;
        const { memberId } = request.params;
        const updates = request.body;

        // Check if user is admin
        if (request.user.role !== 'ADMIN' && request.user.role !== 'SUPERADMIN') {
            return reply.code(403).send({ message: 'Only admins can update team members' });
        }

        // Allowed fields that can be updated
        const allowedUpdates = {};
        const updatableFields = [
            'firstName', 'lastName', 'mobileNumber', 
            'designation', 'department', 'manager', 'role'
        ];

        for (const field of updatableFields) {
            if (updates[field] !== undefined) {
                allowedUpdates[field] = updates[field];
            }
        }

        if (Object.keys(allowedUpdates).length === 0) {
            return reply.code(400).send({ message: 'No valid fields provided to update.' });
        }

        allowedUpdates.updatedAt = new Date();

        const [updatedUser] = await db.update(users)
            .set(allowedUpdates)
            .where(eq(users.userId, memberId))
            .returning();

        if (!updatedUser) {
            return reply.code(404).send({ message: 'User not found' });
        }

        const { password, ...safeUser } = updatedUser;
        return reply.send({ message: 'Team member updated successfully', data: safeUser });
    } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ message: 'Internal Server Error' });
    }
};
