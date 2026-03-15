# New APIs Documentation

## Overview
Complete API implementation for Settings, Export, and Roles management features in the Task Management System.

---

## 1. SETTINGS APIs (`/api/settings`)

### 1.1 General Settings

#### Get General Settings
```
GET /api/settings/general
Authorization: Bearer {JWT_TOKEN}

Response:
{
    "companyName": "string",
    "businessIndustry": "string",
    "companySize": "string"
}
```

#### Update General Settings
```
POST /api/settings/general
Authorization: Bearer {JWT_TOKEN}

Request Body:
{
    "companyName": "ABC Corp",
    "businessIndustry": "Technology",
    "companySize": "51-100"
}

Response:
{
    "message": "Settings updated successfully",
    "data": {
        "id": "uuid",
        "userId": "uuid",
        "companyName": "ABC Corp",
        "businessIndustry": "Technology",
        "companySize": "51-100",
        "createdAt": "timestamp",
        "updatedAt": "timestamp"
    }
}
```

---

### 1.2 Task Update Settings

#### Get Task Update Settings
```
GET /api/settings/task-update
Authorization: Bearer {JWT_TOKEN}

Response:
{
    "remarksRequired": true,
    "attachmentsRequired": false,
    "imagesRequired": false
}
```

#### Update Task Update Settings
```
POST /api/settings/task-update
Authorization: Bearer {JWT_TOKEN}

Request Body:
{
    "remarksRequired": true,
    "attachmentsRequired": false,
    "imagesRequired": false
}

Response:
{
    "message": "Task update settings saved successfully",
    "data": {
        "id": "uuid",
        "userId": "uuid",
        "remarksRequired": true,
        "attachmentsRequired": false,
        "imagesRequired": false,
        "createdAt": "timestamp",
        "updatedAt": "timestamp"
    }
}
```

---

### 1.3 Notification Settings

#### Get Notification Settings
```
GET /api/settings/notifications
Authorization: Bearer {JWT_TOKEN}

Response:
{
    "informaticsNotifications": true,
    "emailNotifications": true,
    "dailyReminder": true,
    "emailReminders": true,
    "taskReminderTime": "09:00",
    "weeklyOnly": false,
    "reminderDays": ["Monday", "Wednesday", "Friday"],
    "notificationChannels": {
        "New Task": { "admin": true, "manager": true, "member": true }
    },
    "notificationFrequency": {
        "New Task": { "admin": "Real-time", "manager": "Hourly", "member": "Daily" }
    }
}
```

#### Update Notification Settings
```
POST /api/settings/notifications
Authorization: Bearer {JWT_TOKEN}

Request Body:
{
    "informaticsNotifications": true,
    "emailNotifications": true,
    "dailyReminder": true,
    "emailReminders": true,
    "taskReminderTime": "09:00",
    "weeklyOnly": false,
    "reminderDays": ["Monday", "Wednesday", "Friday"],
    "notificationChannels": {...},
    "notificationFrequency": {...}
}

Response:
{
    "message": "Notification settings updated successfully",
    "data": { /* settings object */ }
}
```

---

## 2. EXPORT APIs (`/api/exports`)

### Create Export
```
POST /api/exports
Authorization: Bearer {JWT_TOKEN}

Request Body:
{
    "dateRange": "This Month",
    "assignedTo": ["user_id_1", "user_id_2"],
    "assignedBy": ["user_id_3"],
    "taskType": ["General", "Urgent"]
}

Response:
{
    "message": "Export created successfully",
    "data": {
        "id": "uuid",
        "userId": "uuid",
        "dateRange": "This Month",
        "assignedTo": [...],
        "assignedBy": [...],
        "taskType": [...],
        "filePath": "/exports/tasks_export_xxx.csv",
        "fileSize": 51200,
        "exportFormat": "csv",
        "createdAt": "timestamp",
        "expiresAt": "timestamp (60 days)"
    }
}
```

### Get Export Logs (User's Own)
```
GET /api/exports/logs
Authorization: Bearer {JWT_TOKEN}

Response:
{
    "logs": [
        {
            "id": "uuid",
            "userId": "uuid",
            "exportedBy": "John Doe",
            "dateRange": "This Month",
            "assignedTo": [...],
            "assignedBy": [...],
            "taskType": [...],
            "filePath": "string",
            "fileSize": number,
            "exportFormat": "csv",
            "createdAt": "timestamp",
            "expiresAt": "timestamp"
        }
    ]
}
```

### Get All Export Logs (Admin Only)
```
GET /api/exports/admin/logs
Authorization: Bearer {JWT_TOKEN}

Response: (same as above)
```

### Download Export
```
GET /api/exports/{exportId}/download
Authorization: Bearer {JWT_TOKEN}

Response:
{
    "message": "Export file ready for download",
    "data": {
        "id": "uuid",
        "fileName": "tasks_export_xxx.csv",
        "fileSize": 51200,
        "createdAt": "timestamp"
    }
}

Status Codes:
- 200: Success
- 404: Export not found
- 410: Export has expired
- 403: Permission denied
```

### Delete Export Log
```
DELETE /api/exports/{exportId}
Authorization: Bearer {JWT_TOKEN}

Response:
{
    "message": "Export deleted successfully"
}

Status Codes:
- 200: Success
- 404: Export not found
- 403: Permission denied
```

---

## 3. ROLES & PERMISSIONS APIs (`/api/roles`)

### Get All Roles with Permissions
```
GET /api/roles
Authorization: Bearer {JWT_TOKEN}

Response:
{
    "roles": [
        {
            "id": "uuid",
            "name": "Admin",
            "description": "Administrator role",
            "isDefault": true,
            "createdBy": null,
            "createdAt": "timestamp",
            "updatedAt": "timestamp",
            "permissions": {
                "Create": true,
                "Edit": true,
                "View": true,
                "Delete": true,
                "Import Task": true,
                "Export Task": true
            }
        },
        {
            "id": "uuid",
            "name": "Manager",
            "description": "Manager role",
            "isDefault": true,
            "permissions": { /* ... */ }
        },
        {
            "id": "uuid",
            "name": "Team Member",
            "description": "Team Member role",
            "isDefault": true,
            "permissions": { /* ... */ }
        }
    ]
}
```

### Get Single Role with Permissions
```
GET /api/roles/{roleId}
Authorization: Bearer {JWT_TOKEN}

Response:
{
    "role": {
        "id": "uuid",
        "name": "Admin",
        "description": "Administrator role",
        "isDefault": true,
        "permissions": { /* ... */ }
    }
}
```

### Create Custom Role (Admin Only)
```
POST /api/roles
Authorization: Bearer {JWT_TOKEN}

Request Body:
{
    "name": "Supervisor",
    "description": "Supervisor role for team leads"
}

Response:
{
    "message": "Role created successfully",
    "data": {
        "id": "uuid (newly created)",
        "name": "Supervisor",
        "description": "Supervisor role for team leads",
        "isDefault": false,
        "createdBy": "uuid",
        "createdAt": "timestamp",
        "updatedAt": "timestamp"
    }
}

Status Codes:
- 201: Created
- 400: Role name is required
- 403: Only admins can create roles
- 409: Role already exists
```

### Update Role (Admin Only)
```
PUT /api/roles/{roleId}
Authorization: Bearer {JWT_TOKEN}

Request Body:
{
    "name": "Updated Role Name",
    "description": "Updated description"
}

Response:
{
    "message": "Role updated successfully",
    "data": { /* updated role */ }
}

Status Codes:
- 200: Success
- 400: Cannot modify default roles
- 403: Only admins can update roles
- 404: Role not found
```

### Delete Role (Admin Only)
```
DELETE /api/roles/{roleId}
Authorization: Bearer {JWT_TOKEN}

Response:
{
    "message": "Role deleted successfully"
}

Status Codes:
- 200: Success
- 400: Cannot delete default roles
- 403: Only admins can delete roles
- 404: Role not found
```

### Update Role Permissions (Admin Only)
```
PUT /api/roles/{roleId}/permissions
Authorization: Bearer {JWT_TOKEN}

Request Body:
{
    "permissions": {
        "Create": true,
        "Edit": true,
        "View": true,
        "Delete": false,
        "Import Task": true,
        "Export Task": true
    }
}

Response:
{
    "message": "Permissions updated successfully",
    "data": {
        "roleId": "uuid",
        "permissions": {
            "Create": true,
            "Edit": true,
            "View": true,
            "Delete": false,
            "Import Task": true,
            "Export Task": true
        }
    }
}

Status Codes:
- 200: Success
- 403: Only admins can update permissions
- 404: Role not found
```

---

## Database Tables

### user_settings
```sql
CREATE TABLE user_settings (
    id UUID PRIMARY KEY,
    user_id UUID UNIQUE NOT NULL REFERENCES users(user_id),
    company_name VARCHAR(255),
    business_industry VARCHAR(100),
    company_size VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
)
```

### task_update_settings
```sql
CREATE TABLE task_update_settings (
    id UUID PRIMARY KEY,
    user_id UUID UNIQUE NOT NULL REFERENCES users(user_id),
    remarks_required BOOLEAN DEFAULT true,
    attachments_required BOOLEAN DEFAULT false,
    images_required BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
)
```

### notification_settings
```sql
CREATE TABLE notification_settings (
    id UUID PRIMARY KEY,
    user_id UUID UNIQUE NOT NULL REFERENCES users(user_id),
    informatics_notifications BOOLEAN DEFAULT true,
    email_notifications BOOLEAN DEFAULT true,
    daily_reminder BOOLEAN DEFAULT true,
    email_reminders BOOLEAN DEFAULT true,
    task_reminder_time VARCHAR(5) DEFAULT '09:00',
    weekly_only BOOLEAN DEFAULT false,
    reminder_days JSONB DEFAULT '[]',
    notification_channels JSONB DEFAULT '{}',
    notification_frequency JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
)
```

### export_logs
```sql
CREATE TABLE export_logs (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(user_id),
    date_range VARCHAR(100),
    assigned_to JSONB DEFAULT '[]',
    assigned_by JSONB DEFAULT '[]',
    task_type JSONB DEFAULT '[]',
    file_path TEXT,
    file_size INTEGER,
    export_format VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP NOT NULL
)
```

### roles
```sql
CREATE TABLE roles (
    id UUID PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    is_default BOOLEAN DEFAULT false,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
)
```

### role_permissions
```sql
CREATE TABLE role_permissions (
    id UUID PRIMARY KEY,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    action VARCHAR(100) NOT NULL,
    allowed BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
)
```

---

## Default Roles
The system comes with 3 default roles:
1. **Admin** - Full access to all actions
2. **Manager** - Can Create, Edit, View, Import, Export but cannot Delete
3. **Team Member** - Can Create, View only

---

## Error Codes
- `400` - Bad Request (validation error)
- `401` - Unauthorized (invalid/missing JWT)
- `403` - Forbidden (permission denied, admin-only action)
- `404` - Not Found (resource doesn't exist)
- `409` - Conflict (duplicate resource, e.g., role name)
- `410` - Gone (resource expired, e.g., export file)
- `500` - Internal Server Error

---

## Frontend Integration

All new services are already integrated:
- `settings_service.dart` - Settings API calls
- `export_service.dart` - Export API calls
- `roles_service.dart` - Roles & Permissions API calls

Screens using these services:
- `general_settings_screen.dart` - Company info, task update settings, export tasks
- `notifications_reminders_screen.dart` - Notification preferences
- `export_tasks_logs_screen.dart` - View export history
- `role_permission_screen.dart` - Manage roles and permissions
