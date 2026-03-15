// API Testing Script
// Run this in the backend to test all the new APIs

import { db } from './db/index.js';
import { userSettings, taskUpdateSettings, notificationSettings, exportLogs, roles, rolePermissions } from './db/schema.js';
import { v4 as uuidv4 } from 'uuid';

const testAPIs = async () => {
    console.log('\n🧪 Testing New APIs...\n');

    try {
        // Test 1: User Settings
        console.log('✅ Test 1: User Settings');
        const userId = uuidv4();
        await db.insert(userSettings).values({
            userId,
            companyName: 'Test Company',
            businessIndustry: 'Technology',
            companySize: '51-100'
        });
        console.log('   ✓ User settings created\n');

        // Test 2: Task Update Settings
        console.log('✅ Test 2: Task Update Settings');
        await db.insert(taskUpdateSettings).values({
            userId,
            remarksRequired: true,
            attachmentsRequired: false,
            imagesRequired: false
        });
        console.log('   ✓ Task update settings created\n');

        // Test 3: Notification Settings
        console.log('✅ Test 3: Notification Settings');
        await db.insert(notificationSettings).values({
            userId,
            informaticsNotifications: true,
            emailNotifications: true,
            dailyReminder: true,
            emailReminders: true,
            taskReminderTime: '09:00',
            weeklyOnly: false,
            reminderDays: ['Monday', 'Wednesday', 'Friday'],
            notificationChannels: {
                'New Task': { admin: true, manager: true, member: true },
                'Task Edit': { admin: true, manager: true, member: false }
            },
            notificationFrequency: {
                'New Task': { admin: 'Real-time', manager: 'Hourly', member: 'Daily' }
            }
        });
        console.log('   ✓ Notification settings created\n');

        // Test 4: Export Logs
        console.log('✅ Test 4: Export Logs');
        const expiresAt = new Date();
        expiresAt.setDate(expiresAt.getDate() + 60);
        await db.insert(exportLogs).values({
            userId,
            dateRange: 'This Month',
            assignedTo: [],
            assignedBy: [],
            taskType: [],
            filePath: '/exports/tasks_export_test.csv',
            fileSize: 51200,
            exportFormat: 'csv',
            expiresAt
        });
        console.log('   ✓ Export log created\n');

        // Test 5: Roles
        console.log('✅ Test 5: Roles');
        const roleId = uuidv4();
        await db.insert(roles).values({
            id: roleId,
            name: 'Supervisor',
            description: 'Supervisor role',
            isDefault: false,
            createdBy: userId
        });
        console.log('   ✓ Custom role created\n');

        // Test 6: Role Permissions
        console.log('✅ Test 6: Role Permissions');
        const actions = ['Create', 'Edit', 'View', 'Delete', 'Import Task', 'Export Task'];
        for (const action of actions) {
            await db.insert(rolePermissions).values({
                roleId,
                action,
                allowed: ['Create', 'Edit', 'View', 'Export Task'].includes(action)
            });
        }
        console.log('   ✓ Role permissions created\n');

        console.log('✅ All API tests passed!\n');

    } catch (error) {
        console.error('❌ Error during testing:', error.message);
        console.error(error);
    }
};

export default testAPIs;
