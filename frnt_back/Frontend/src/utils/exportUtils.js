import * as XLSX from 'xlsx';

/**
 * Exports data to an Excel file
 * @param {Array} data - Array of objects to export
 * @param {string} fileName - Name of the file (without extension)
 * @param {string} sheetName - Name of the worksheet
 */
export const exportToExcel = (data, fileName = 'exported-data', sheetName = 'Data') => {
    // Create a new workbook
    const wb = XLSX.utils.book_new();
    
    // Convert data to worksheet
    const ws = XLSX.utils.json_to_sheet(data);
    
    // Add the worksheet to the workbook
    XLSX.utils.book_append_sheet(wb, ws, sheetName);
    
    // Generate buffer and trigger download
    XLSX.writeFile(wb, `${fileName}.xlsx`);
};

/**
 * Formats task data specifically for Excel export
 * @param {Array} tasks - Array of task objects
 * @param {Array} users - Array of user objects to resolve names
 * @returns {Array} - Formatted objects for export
 */
export const formatTasksForExport = (tasks, users = []) => {
    const getUserName = (userId) => {
        const u = users.find(u => u.userId === userId || u.id === userId);
        return u ? `${u.firstName} ${u.lastName}` : (userId || 'Unknown');
    };

    return tasks.map(t => {
        // Parse tags if they are stringified
        let tags = '';
        try {
            const parsedTags = typeof t.tags === 'string' ? JSON.parse(t.tags) : (t.tags || []);
            tags = Array.isArray(parsedTags) ? parsedTags.map(tag => tag.text || tag).join(', ') : '';
        } catch (e) {
            tags = '';
        }

        // Format checklist
        let checklist = '';
        try {
            const parsedChecklist = typeof t.checklistItems === 'string' ? JSON.parse(t.checklistItems) : (t.checklistItems || []);
            checklist = Array.isArray(parsedChecklist) 
                ? parsedChecklist.map(item => `[${item.completed ? 'X' : ' '}] ${item.itemName || item.text || ''}`).join('\n') 
                : '';
        } catch (e) {
            checklist = '';
        }

        return {
            'Task Title': t.taskTitle || '',
            'Description': t.description || '',
            'Status': t.status || '',
            'Priority': t.priority || '',
            'Category': t.category || '',
            'Assigner': `${t.assignerFirstName || ''} ${t.assignerLastName || ''}`.trim() || getUserName(t.assignerId),
            'Assignee (Doer)': `${t.doerFirstName || ''} ${t.doerLastName || ''}`.trim() || getUserName(t.doerId),
            'Due Date': t.dueDate ? new Date(t.dueDate).toLocaleDateString('en-GB') : 'N/A',
            'Created At': t.createdAt ? new Date(t.createdAt).toLocaleDateString('en-GB') : 'N/A',
            'Tags': tags,
            'Checklist Items': checklist
        };
    });
};
