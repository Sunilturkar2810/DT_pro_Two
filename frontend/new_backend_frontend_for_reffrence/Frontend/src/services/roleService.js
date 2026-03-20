import api from './api';

class RoleService {
    getRoles() {
        return api.get('/roles');
    }

    createRole(data) {
        return api.post('/roles', data);
    }

    updateRole(id, data) {
        return api.put(`/roles/${id}`, data);
    }

    deleteRole(id) {
        return api.delete(`/roles/${id}`);
    }
}

export default new RoleService();
