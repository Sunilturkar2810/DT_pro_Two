import { db } from '../db/index.js';
import { users } from '../db/schema.js';
import { eq } from 'drizzle-orm';
import { hashPassword, comparePassword } from '../utils/auth.js';

export const register = async (request, reply) => {
    const {
        firstName,
        lastName,
        workEmail,
        password,
        mobileNumber,
        role,
        designation,
        department
    } = request.body;

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
            department
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
    const allowedRoles = ['Admin', 'SuperAdmin', 'Manager', 'User'];
    
    if (!allowedRoles.includes(performerRole)) {
        return reply.code(403).send({ 
            message: `Forbidden: You do not have permission to bulk register users. Your current role is '${performerRole}'`,
            debugUser: request.user
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
                    department: userData.department
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
            email: user.workEmail
        });

        // Remove sensitive information
        const { password: _, ...safeUser } = user;

        return reply.send({
            message: 'Login successful',
            token,
            user: {
                ...safeUser,
                id: safeUser.userId // Ensure id is also present for compatibility
            }
        });
    } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ message: 'Internal Server Error' });
    }
};
export const getUsers = async (request, reply) => {
    try {
        const allUsers = await db.query.users.findMany();
        
        // Remove password from all users
        const safeUsers = allUsers.map(({ password, ...user }) => user);

        // Changed to send { users: [...] } so Flutter's response.data['users'] works
        const filteredUsers = safeUsers.filter(u => u.role !== 'Deleted');
        return reply.send({ users: filteredUsers });
    } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ message: 'Internal Server Error' });
    }
};

export const deleteUser = async (request, reply) => {
    const { id } = request.params;
    const performerRole = request.user?.role;

    // Only Admin can delete users
    if (performerRole !== 'Admin' && performerRole !== 'SuperAdmin') {
        return reply.code(403).send({ message: 'Forbidden: Only Admins can delete users' });
    }

    try {
        // Soft delete/anonymize to handle foreign key constraints from tasks and relations
        const [deletedUser] = await db.update(users)
            .set({ 
                firstName: 'Deleted', 
                lastName: 'Account', 
                workEmail: `deleted_${id}@system.local`, 
                password: 'deleted', 
                role: 'Deleted',
                mobileNumber: '0000000000'
            })
            .where(eq(users.userId, id))
            .returning();
            
        if (!deletedUser) {
            return reply.code(404).send({ message: 'User not found' });
        }
        return reply.send({ message: 'User deleted successfully' });
    } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ message: 'Internal Server Error', debug: error.message });
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

export const forgotPassword = async (request, reply) => {
    const { workEmail } = request.body;
    try {
        const user = await db.query.users.findFirst({
            where: eq(users.workEmail, workEmail)
        });

        if (!user) {
            return reply.code(404).send({ message: 'User not found' });
        }

        const resetToken = request.server.jwt.sign({ email: user.workEmail }, { expiresIn: '15m' });
        
        return reply.send({
            message: 'Password reset token generated',
            resetToken
        });
    } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ message: 'Internal Server Error' });
    }
};

export const resetPassword = async (request, reply) => {
    const { resetToken, newPassword } = request.body;
    try {
        const decoded = request.server.jwt.verify(resetToken);
        const email = decoded.email;

        const user = await db.query.users.findFirst({
            where: eq(users.workEmail, email)
        });

        if (!user) {
            return reply.code(404).send({ message: 'User not found' });
        }

        const hashedPassword = await hashPassword(newPassword);

        await db.update(users)
            .set({ password: hashedPassword })
            .where(eq(users.workEmail, email));

        return reply.send({ message: 'Password has been reset successfully' });
    } catch (error) {
        request.log.error(error);
        return reply.code(400).send({ message: 'Invalid or expired token' });
    }
};

export const updateProfile = async (request, reply) => {
    try {
        const userId = request.user.id;
        const updates = request.body;

        const allowedUpdates = {};
        const updatableFields = [
            'firstName', 'lastName', 'mobileNumber', 'profilePhotoUrl', 'theme',
            'personalEmail', 'emergencyMobileNo', 'dateOfBirth', 'maritalStatus', 'gender',
            'address', 'city', 'state', 'nationality', 'joiningDate', 'currentSalary',
            'designation', 'department', 'manager'
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
            .where(eq(users.userId, userId))
            .returning();

        if (!updatedUser) {
            return reply.code(404).send({ message: 'User not found' });
        }

        const { password, ...safeUser } = updatedUser;
        return reply.send({ message: 'Profile updated successfully', data: safeUser });
    } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ message: 'Internal Server Error' });
    }
};

