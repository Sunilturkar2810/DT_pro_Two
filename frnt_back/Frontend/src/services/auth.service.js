import api from './api';

const login = async (workEmail, password) => {
    const response = await api.post('/auth/login', { workEmail, password });
    if (response.data.token) {
        console.log("auth login" + response.data);
        localStorage.setItem('user', JSON.stringify(response.data));
    }
    return response.data;
};

const register = async (userData) => {
    const response = await api.post('/auth/register', userData);
    return response.data;
};

const bulkRegister = async (users) => {
    const response = await api.post('/auth/bulk-register', { users });
    return response.data;
};

const logout = () => {
    localStorage.removeItem('user');
};

const getCurrentUser = () => {
    return JSON.parse(localStorage.getItem('user'));
};

const getMe = async () => {
    const response = await api.get('/auth/me');
    return response.data;
};

const getRoles = async () => {
    const response = await api.get('/auth/roles');
    return response.data;
};

const createRole = async (roleData) => {
    const response = await api.post('/auth/roles/create', roleData);
    return response.data;
};

const updateUser = async (userId, userData) => {
    const response = await api.put(`/auth/users/${userId}`, userData);
    return response.data;
};

const updateCredentials = async (userId, credentialsData) => {
    const response = await api.put(`/auth/users/${userId}/credentials`, credentialsData);
    return response.data;
};

const updatePassword = async (userId, currentPassword, newPassword) => {
    const response = await api.put(`/auth/update-password/${userId}`, {
        currentPassword,
        newPassword
    });
    return response.data;
};

const uploadProfileImage = async (formData) => {
    const response = await api.post('/upload/profile-image', formData, {
        headers: { 'Content-Type': 'multipart/form-data' }
    });
    return response.data;
};

const deleteAllTasks = async (userId, confirmEmail) => {
    const response = await api.delete(`/auth/users/${userId}/tasks`, { data: { confirmEmail } });
    return response.data;
};

const deleteUser = async (userId) => {
    const response = await api.delete(`/auth/users/${userId}`);
    return response.data;
};

const authService = {
    login,
    register,
    bulkRegister,
    logout,
    getCurrentUser,
    getMe,
    getRoles,
    createRole,
    updateUser,
    updateCredentials,
    updatePassword,
    uploadProfileImage,
    deleteAllTasks,
    deleteUser
};

export default authService;
