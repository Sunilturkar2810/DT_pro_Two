import { db } from '../db/index.js';
import {
    users, delegations, teamMembers, revisionHistory, remarkHistory, teams,
    notifications, checklistMaster, categories, groups, groupMembers, roles,
    deletedAccounts
} from '../db/schema.js';
import { eq, or, inArray } from 'drizzle-orm';
import { hashPassword, comparePassword } from '../utils/auth.js';

export const register = async (request, reply) => {
    console.log('Register Request by:', request.user);
    // Role check: ADMIN, SUPERADMIN, MANAGER or User (for testing)
    const performerRole = request.user?.role;
    const allowedRoles = ['ADMIN', 'SUPERADMIN', 'MANAGER'];
    const normalizedRole = performerRole?.trim().toUpperCase();

    console.log(`[Permission Check] Performer: ${performerRole}, Normalized: "${normalizedRole}", Allowed: [${allowedRoles.join(', ')}], Match: ${allowedRoles.includes(normalizedRole)}`);

    if (!allowedRoles.includes(normalizedRole)) {
        return reply.code(403).send({
            message: `Forbidden: You do not have permission to register new users. Your current role is '${performerRole}'`,
            debugInfo: { performerRole, normalizedRole, allowedRoles }
        });
    }

    const {
        firstName,
        lastName,
        workEmail,
        password,
        mobileNumber,
        role,
        designation,
        department,
        reportingManagerId,
        taskAccess,
        leaveAccess
    } = request.body;

    if (performerRole === 'MANAGER' && ['ADMIN', 'SUPERADMIN'].includes(role?.toUpperCase())) {
        return reply.code(403).send({ message: `Forbidden: MANAGERS cannot create ADMIN or SUPERADMIN accounts.` });
    }

    try {
        // Check if user exists
        const existingUser = await db.query.users.findFirst({
            where: eq(users.workEmail, workEmail)
        });

        if (existingUser) {
            return reply.code(400).send({ message: `User with email ${workEmail} already exists` });
        }

        const hashedPassword = await hashPassword(password);

        const newUser = await db.insert(users).values({
            firstName,
            lastName,
            workEmail,
            password: hashedPassword,
            mobileNumber,
            role,
            designation,
            department,
            reportingManagerId: reportingManagerId || null,
            taskAccess: taskAccess ?? true,
            leaveAccess: leaveAccess ?? true,
            status: 'active',
            addedBy: request.user?.id
        }).returning();

        return reply.code(201).send({
            message: 'User registered successfully',
            user: {
                id: newUser[0].userId,
                workEmail: newUser[0].workEmail
            }
        });
    } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ message: 'Internal Server Error' });
    }
};

export const bulkRegister = async (request, reply) => {
    const performerRole = request.user?.role;
    const allowedRoles = ['ADMIN', 'SUPERADMIN', 'MANAGER', 'USER'];
    const normalizedRole = performerRole?.trim().toUpperCase();

    console.log(`[Bulk Permission Check] Performer: ${performerRole}, Normalized: "${normalizedRole}", Allowed: [${allowedRoles.join(', ')}], Match: ${allowedRoles.includes(normalizedRole)}`);

    if (!allowedRoles.includes(normalizedRole)) {
        return reply.code(403).send({
            message: `Forbidden: You do not have permission to bulk register users. Your current role is '${performerRole}'`,
            debugInfo: { performerRole, normalizedRole, allowedRoles }
        });
    }

    const { users: userList } = request.body;

    if (!Array.isArray(userList) || userList.length === 0) {
        return reply.code(400).send({ message: 'Invalid user list' });
    }

    const results = {
        success: [],
        failed: []
    };

    try {
        for (const userData of userList) {
            try {
                if (performerRole === 'MANAGER' && ['ADMIN', 'SUPERADMIN'].includes(userData.role?.toUpperCase())) {
                    results.failed.push({ email: userData.workEmail, reason: 'MANAGERS cannot create ADMIN or SUPERADMIN accounts.' });
                    continue;
                }

                // Check if user exists
                const existingUser = await db.query.users.findFirst({
                    where: eq(users.workEmail, userData.workEmail)
                });

                if (existingUser) {
                    results.failed.push({ email: userData.workEmail, reason: 'Email already exists' });
                    continue;
                }

                const hashedPassword = await hashPassword(userData.password);

                const [newUser] = await db.insert(users).values({
                    firstName: userData.firstName,
                    lastName: userData.lastName,
                    workEmail: userData.workEmail,
                    password: hashedPassword,
                    mobileNumber: userData.mobileNumber,
                    role: userData.role || 'User',
                    designation: userData.designation,
                    department: userData.department,
                    reportingManagerId: userData.reportingManagerId || null,
                    taskAccess: userData.taskAccess ?? true,
                    leaveAccess: userData.leaveAccess ?? true,
                    status: 'active',
                    addedBy: request.user?.id
                }).returning();

                results.success.push({ id: newUser.userId, email: newUser.workEmail });
            } catch (err) {
                request.log.error(err);
                results.failed.push({ email: userData.workEmail, reason: err.message });
            }
        }

        return reply.code(201).send({
            message: `Processed ${userList.length} users`,
            results
        });
    } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ message: 'Internal Server Error' });
    }
};

export const login = async (request, reply) => {
    const { workEmail, password } = request.body;

    try {
        const user = await db.query.users.findFirst({
            where: eq(users.workEmail, workEmail)
        });

        if (!user) {
            return reply.code(401).send({ message: 'Invalid credentials' });
        }

        const isMatch = await comparePassword(password, user.password);
        if (!isMatch) {
            return reply.code(401).send({ message: 'Invalid credentials' });
        }

        const token = request.server.jwt.sign({
            id: user.userId,
            role: user.role,
            email: user.workEmail,
            firstName: user.firstName,
            lastName: user.lastName,
        });

        return reply.send({
            message: 'Login successful',
            token,
            user: {
                id: user.userId,
                firstName: user.firstName,
                lastName: user.lastName,
                role: user.role,
                designation: user.designation,
                department: user.department,
            }
        });
    } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ message: 'Internal Server Error' });
    }
};
export const getUsers = async (request, reply) => {
    try {
        const allUsers = await db.select({
            userId: users.userId,
            firstName: users.firstName,
            lastName: users.lastName,
            workEmail: users.workEmail,
            role: users.role,
            designation: users.designation,
            department: users.department,
            mobileNumber: users.mobileNumber,
            manager: users.manager,
            reportingManagerId: users.reportingManagerId,
            status: users.status,
        }).from(users);
        return reply.send(allUsers);
    } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ message: 'Internal Server Error' });
    }
};
export const getMe = async (request, reply) => {
    try {
        const userId = request.user.id;
        const user = await db.query.users.findFirst({
            where: eq(users.userId, userId)
        });

        if (!user) {
            return reply.code(404).send({ message: 'User not found' });
        }

        // Remove sensitive information
        const { password, ...safeUser } = user;

        return reply.send(safeUser);
    } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ message: 'Internal Server Error' });
    }
};

export const updateUser = async (request, reply) => {
    const { userId } = request.params;
    const {
        firstName,
        lastName,
        mobileNumber,
        role,
        designation,
        department,
        reportingManagerId,
        taskAccess,
        leaveAccess
    } = request.body;

    try {
        await db.update(users).set({
            firstName,
            lastName,
            mobileNumber,
            role,
            designation,
            department,
            reportingManagerId,
            taskAccess,
            leaveAccess,
            updatedAt: new Date()
        }).where(eq(users.userId, userId));

        return reply.send({ message: 'User updated successfully' });
    } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ message: 'Internal Server Error' });
    }
};

export const updateCredentials = async (request, reply) => {
    const { userId } = request.params;
    const { oldPassword, newPassword, newEmail } = request.body;

    try {
        const user = await db.query.users.findFirst({
            where: eq(users.userId, userId)
        });

        if (!user) {
            return reply.code(404).send({ message: 'User not found' });
        }

        const isMatch = await comparePassword(oldPassword, user.password);
        if (!isMatch) {
            return reply.code(401).send({ message: 'Incorrect old password' });
        }

        const updateData = { updatedAt: new Date() };
        if (newPassword) {
            updateData.password = await hashPassword(newPassword);
        }
        if (newEmail) {
            updateData.workEmail = newEmail;
        }

        await db.update(users).set(updateData).where(eq(users.userId, userId));

        return reply.send({ message: 'Credentials updated successfully' });
    } catch (error) {
        if (error.code === '23505') {
            return reply.code(400).send({ message: 'Email already exists' });
        }
        request.log.error(error);
        return reply.code(500).send({ message: 'Internal Server Error' });
    }
};

export const deleteAllTasks = async (request, reply) => {
    const performer = request.user;
    const isAdmin = performer && (performer.role === 'ADMIN' || performer.role === 'SUPERADMIN');

    if (!isAdmin) {
        return reply.code(403).send({ message: 'Forbidden: Only admins can perform a bulk task wipe.' });
    }

    const { userId } = request.params;
    const { confirmEmail } = request.body;

    try {
        const user = await db.query.users.findFirst({
            where: eq(users.userId, userId)
        });

        if (!user || user.workEmail !== confirmEmail) {
            return reply.code(400).send({ message: 'Confirmation email does not match' });
        }

        // Get delegation IDs to delete from history tables first
        const userDelegations = await db.select({ id: delegations.id }).from(delegations).where(
            or(
                eq(delegations.assignerId, userId),
                eq(delegations.doerId, userId)
            )
        );

        if (userDelegations.length > 0) {
            const delegationIds = userDelegations.map(d => d.id);

            // 1. Delete recurring task templates linked to these delegations
            await db.delete(checklistMaster).where(inArray(checklistMaster.delegationId, delegationIds));

            // 2. Delete history
            await db.delete(revisionHistory).where(inArray(revisionHistory.delegationId, delegationIds));
            await db.delete(remarkHistory).where(inArray(remarkHistory.delegationId, delegationIds));

            // 3. Delete related notifications
            await db.delete(notifications).where(inArray(notifications.relatedId, delegationIds));

            // 4. Finally delete delegations
            await db.delete(delegations).where(inArray(delegations.id, delegationIds));
        }

        return reply.send({ message: 'All tasks deleted successfully' });
    } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ message: 'Internal Server Error' });
    }
};

export const deleteUser = async (request, reply) => {
    const performer = request.user;
    const isAdmin = performer && (performer.role === 'ADMIN' || performer.role === 'SUPERADMIN');

    if (!isAdmin) {
        return reply.code(403).send({ message: 'Forbidden: Only admins can delete user accounts.' });
    }

    const { userId } = request.params;
    const performerId = performer.id; // Use this to reassign orphaned 'addedBy' fields

    try {
        // 1. Notifications - Delete all notifications involving this user
        await db.delete(notifications).where(eq(notifications.recipientId, userId));

        // 2. Team Memberships
        // - Delete their own membership
        await db.delete(teamMembers).where(eq(teamMembers.userId, userId));
        // - Reassign 'addedBy' for others they added
        await db.update(teamMembers).set({ addedBy: performerId }).where(eq(teamMembers.addedBy, userId));
        // - Clear 'reportsTo' for others who reported to them
        await db.update(teamMembers).set({ reportsTo: null }).where(eq(teamMembers.reportsTo, userId));

        // 3. User Table Self-References
        await db.update(users).set({ reportingManagerId: null }).where(eq(users.reportingManagerId, userId));

        // 4. Group Memberships
        await db.delete(groupMembers).where(eq(groupMembers.userId, userId));
        await db.update(groupMembers).set({ addedBy: performerId }).where(eq(groupMembers.addedBy, userId));

        // 5. Teams created by the user
        const userTeams = await db.select({ teamId: teams.teamId }).from(teams).where(eq(teams.createdBy, userId));
        if (userTeams.length > 0) {
            const teamIds = userTeams.map(t => t.teamId);
            await db.delete(teamMembers).where(inArray(teamMembers.teamId, teamIds));
            await db.delete(teams).where(inArray(teams.teamId, teamIds));
        }

        // 6. Delegations and Histories
        const userDelegations = await db.select({ id: delegations.id }).from(delegations).where(
            or(eq(delegations.assignerId, userId), eq(delegations.doerId, userId))
        );

        if (userDelegations.length > 0) {
            const delegationIds = userDelegations.map(d => d.id);
            // Delete recurring task templates
            await db.delete(checklistMaster).where(inArray(checklistMaster.delegationId, delegationIds));
            // History
            await db.delete(revisionHistory).where(inArray(revisionHistory.delegationId, delegationIds));
            await db.delete(remarkHistory).where(inArray(remarkHistory.delegationId, delegationIds));
            // Notifications related to these delegations
            await db.delete(notifications).where(inArray(notifications.relatedId, delegationIds));
            // The tasks themselves
            await db.delete(delegations).where(inArray(delegations.id, delegationIds));
        }

        // 7. Recurring task templates (where user is directly referenced)
        await db.delete(checklistMaster).where(or(eq(checklistMaster.assignerId, userId), eq(checklistMaster.doerId, userId), eq(checklistMaster.verifierId, userId)));

        // 8. Categories and Groups (Metadata) - Reassign to prevent 500
        await db.update(categories).set({ createdBy: performerId }).where(eq(categories.createdBy, userId));
        await db.update(groups).set({ createdBy: performerId }).where(eq(groups.createdBy, userId));
        await db.update(roles).set({ createdBy: performerId }).where(eq(roles.createdBy, userId));

        // 9. Remaining Histories
        await db.delete(remarkHistory).where(eq(remarkHistory.userId, userId));
        await db.delete(revisionHistory).where(eq(revisionHistory.changedBy, userId));

        // 10. Fetch user info before deletion to save to deletedAccounts
        const userToDeleteArr = await db.select().from(users).where(eq(users.userId, userId));
        if (userToDeleteArr.length > 0) {
            const userToDelete = userToDeleteArr[0];
            await db.insert(deletedAccounts).values({
                originalUserId: userToDelete.userId,
                firstName: userToDelete.firstName,
                lastName: userToDelete.lastName,
                workEmail: userToDelete.workEmail,
                mobileNumber: userToDelete.mobileNumber,
                role: userToDelete.role,
                designation: userToDelete.designation,
                department: userToDelete.department,
                deletedBy: performerId
            });
        }

        // 11. SOFT DELETE USER (Update status instead of hard delete)
        await db.update(users).set({ status: 'Delete' }).where(eq(users.userId, userId));

        return reply.send({ message: 'User and all associated dependencies handled successfully' });
    } catch (error) {
        request.log.error(error);
        return reply.code(500).send({
            message: 'Internal Server Error during cascading delete',
            error: error.message
        });
    }
};
