import bcrypt from 'bcryptjs';

const SALT_ROUNDS = 10;

export const hashPassword = async (password) => {
    return await bcrypt.hash(password, SALT_ROUNDS);
};

export const comparePassword = async (password, hash) => {
    return await bcrypt.compare(password, hash);
};

// Helper function to format user response with proper field names
export const formatUserResponse = (user) => {
    if (!user) return null;
    
    const { password, ...safeUser } = user;
    
    // Ensure all expected fields are present with proper naming
    return {
        id: safeUser.userId || safeUser.id,
        userId: safeUser.userId || safeUser.id,
        firstName: safeUser.firstName,
        lastName: safeUser.lastName,
        workEmail: safeUser.workEmail,
        personalEmail: safeUser.personalEmail,
        mobileNumber: safeUser.mobileNumber,
        emergencyMobileNo: safeUser.emergencyMobileNo,
        role: safeUser.role,
        designation: safeUser.designation,
        department: safeUser.department,
        dateOfBirth: safeUser.dateOfBirth,
        profilePhotoUrl: safeUser.profilePhotoUrl,
        resumeUrl: safeUser.resumeUrl,
        salary: safeUser.salary,
        lastIncrement: safeUser.lastIncrement,
        currentSalary: safeUser.currentSalary,
        joiningDate: safeUser.joiningDate,
        manager: safeUser.manager,
        contract: safeUser.contract,
        maritalStatus: safeUser.maritalStatus,
        anniversaryDate: safeUser.anniversaryDate,
        gender: safeUser.gender,
        address: safeUser.address,
        city: safeUser.city,
        state: safeUser.state,
        nationality: safeUser.nationality,
        theme: safeUser.theme || 'light',
        createdAt: safeUser.createdAt,
        updatedAt: safeUser.updatedAt,
    };
};
