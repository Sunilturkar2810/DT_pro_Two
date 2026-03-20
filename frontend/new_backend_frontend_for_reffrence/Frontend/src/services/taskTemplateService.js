import api from './api';

const taskTemplateService = {
    createTemplate: async (templateData) => {
        const response = await api.post('/task-templates', templateData);
        return response.data;
    },
    getTemplates: async () => {
        const response = await api.get('/task-templates');
        return response.data;
    },
    updateTemplate: async (id, updates) => {
        const response = await api.put(`/task-templates/${id}`, updates);
        return response.data;
    },
    deleteTemplate: async (id) => {
        const response = await api.delete(`/task-templates/${id}`);
        return response.data;
    }
};

export default taskTemplateService;
