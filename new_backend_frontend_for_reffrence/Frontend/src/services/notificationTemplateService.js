import api from './api';

const notificationTemplateService = {
    getTemplates: async () => {
        const response = await api.get('/notification-templates');
        return response.data;
    },

    getTemplate: async (eventName, channel) => {
        const response = await api.get(`/notification-templates/${eventName}/${channel}`);
        return response.data;
    },

    saveTemplate: async (templateData) => {
        const response = await api.post('/notification-templates', templateData);
        return response.data;
    },

    deleteTemplate: async (id) => {
        const response = await api.delete(`/notification-templates/${id}`);
        return response.data;
    }
};

export default notificationTemplateService;
