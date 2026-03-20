import api from './api';

const activityService = {
    getActivities: async (filters = {}) => {
        const cleanFilters = Object.fromEntries(
            Object.entries(filters).filter(([_, v]) => v != null && v !== '' && v !== 'This Month')
        );
        const query = new URLSearchParams(cleanFilters).toString();
        const response = await api.get(`/activities?${query}`);
        return response.data;
    }
};

export default activityService;
