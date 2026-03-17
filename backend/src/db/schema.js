import { pgTable, text, timestamp, uuid, numeric, date, varchar, integer, boolean, jsonb } from 'drizzle-orm/pg-core';

export const users = pgTable('users', {
  userId: uuid('user_id').primaryKey().defaultRandom(),
  firstName: varchar('first_name', { length: 255 }).notNull(),
  lastName: varchar('last_name', { length: 255 }).notNull(),
  workEmail: varchar('work_email', { length: 255 }).notNull().unique(),
  personalEmail: varchar('personal_email', { length: 255 }),
  password: text('password').notNull(),
  mobileNumber: varchar('mobile_number', { length: 20 }).notNull(),
  emergencyMobileNo: varchar('emergency_mobile_no', { length: 20 }),
  role: varchar('role', { length: 50 }).notNull(),
  designation: varchar('designation', { length: 100 }).notNull(),
  department: varchar('department', { length: 100 }).notNull(),
  dateOfBirth: date('date_of_birth'),
  profilePhotoUrl: text('profile_photo_url'),
  resumeUrl: text('resume_url'),
  salary: numeric('salary', { precision: 12, scale: 2 }),
  lastIncrement: numeric('last_increment', { precision: 12, scale: 2 }),
  currentSalary: numeric('current_salary', { precision: 12, scale: 2 }),
  joiningDate: date('joining_date'),
  manager: varchar('manager', { length: 255 }),
  contract: text('contract'),
  maritalStatus: varchar('marital_status', { length: 50 }),
  anniversaryDate: date('anniversary_date'),
  gender: varchar('gender', { length: 20 }),
  address: text('address'),
  city: varchar('city', { length: 100 }),
  state: varchar('state', { length: 100 }),
  nationality: varchar('nationality', { length: 100 }),
  theme: varchar('theme', { length: 20 }).default('light'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export const delegations = pgTable('delegations', {
  id: uuid('id').primaryKey().defaultRandom(),
  taskTitle: varchar('task_title', { length: 255 }).notNull(),
  description: text('description'),
  assignerId: uuid('assigner_id').references(() => users.userId).notNull(),
  doerId: uuid('doer_id').references(() => users.userId).notNull(),
  category: varchar('category', { length: 100 }),
  priority: varchar('priority', { length: 50 }),
  status: varchar('status', { length: 50 }).default('Pending'),
  dueDate: date('due_date'),
  voiceNoteUrl: text('voice_note_url'),
  referenceDocs: text('reference_docs'),
  tags: jsonb('tags'),
  evidenceRequired: boolean('evidence_required').default(false),
  evidenceUrl: text('evidence_url'),
  checklistItems: jsonb('checklist_items'),
  revisionCount: integer('revision_count').default(0),
  inLoopIds: jsonb('in_loop_ids'),
  parentId: uuid('parent_id'),
  groupId: uuid('group_id'),
  deletedAt: timestamp('deleted_at'),
  deletedBy: uuid('deleted_by'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export const revisionHistory = pgTable('revision_history', {
  id: uuid('id').primaryKey().defaultRandom(),
  delegationId: uuid('delegation_id').references(() => delegations.id).notNull(),
  oldDueDate: date('old_due_date'),
  newDueDate: date('new_due_date'),
  oldStatus: varchar('old_status', { length: 50 }),
  newStatus: varchar('new_status', { length: 50 }),
  reason: text('reason'),
  changedBy: uuid('changed_by').references(() => users.userId).notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export const remarkHistory = pgTable('remark_history', {
  id: uuid('id').primaryKey().defaultRandom(),
  delegationId: uuid('delegation_id').references(() => delegations.id).notNull(),
  userId: uuid('user_id').references(() => users.userId).notNull(),
  remark: text('remark').notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

export const teams = pgTable('teams', {
  teamId: uuid('team_id').primaryKey().defaultRandom(),
  name: varchar('name', { length: 255 }).notNull(),
  description: text('description'),
  createdBy: uuid('created_by').references(() => users.userId).notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export const teamMembers = pgTable('team_members', {
  id: uuid('id').primaryKey().defaultRandom(),
  teamId: uuid('team_id').references(() => teams.teamId).notNull(),
  userId: uuid('user_id').references(() => users.userId).notNull(),
  role: varchar('role', { length: 50 }).notNull(), // Team Member, Manager, Admin
  reportsTo: uuid('reports_to').references(() => users.userId),
  addedBy: uuid('added_by').references(() => users.userId).notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

export const notifications = pgTable('notifications', {
  id: uuid('id').primaryKey().defaultRandom(),
  recipientId: uuid('recipient_id').references(() => users.userId).notNull(),
  title: varchar('title', { length: 255 }).notNull(),
  message: text('message').notNull(),
  type: varchar('type', { length: 50 }).notNull(), // delegation, remark, revision, status_change, system
  relatedId: uuid('related_id'), // usually delegationId
  isRead: boolean('is_read').default(false).notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// For generic recurring task templates assigned via "Use Task Template" drop-down
export const taskTemplateChecklistMaster = pgTable('task_template_checklist_master', {
  id: uuid('id').primaryKey().defaultRandom(),
  itemName: text('item_name').notNull(),
  assigneeId: uuid('assignee_id').references(() => users.userId),
  doerId: uuid('doer_id').references(() => users.userId),
  priority: varchar('priority', { length: 50 }),
  category: varchar('category', { length: 100 }),
  verificationRequired: boolean('verification_required').default(false),
  verifierId: uuid('verifier_id').references(() => users.userId),
  attachmentRequired: boolean('attachment_required').default(false),
  frequency: varchar('frequency', { length: 50 }), // Daily, Weekly, Monthly etc
  fromDate: date('from_date'),
  dueDate: date('due_date'),
  weeklyDays: jsonb('weekly_days'), // e.g., ["Monday", "Wednesday"]
  selectedDates: jsonb('selected_dates'), // e.g., ["01", "15"]
  intervalDays: integer('interval_days'),
  occurEveryMode: varchar('occur_every_mode', { length: 50 }),
  occurValue: integer('occur_value'),
  occurDays: jsonb('occur_days'),
  occurDates: jsonb('occur_dates'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// For individual items triggered from a generic `task_template_checklist_master` (if needed to stand alone)
export const taskTemplateChecklist = pgTable('task_template_checklist', {
  id: uuid('id').primaryKey().defaultRandom(),
  masterId: uuid('master_id').references(() => taskTemplateChecklistMaster.id),
  itemName: text('item_name').notNull(),
  assigneeId: uuid('assignee_id').references(() => users.userId),
  doerId: uuid('doer_id').references(() => users.userId),
  priority: varchar('priority', { length: 50 }),
  category: varchar('category', { length: 100 }),
  verificationRequired: boolean('verification_required').default(false),
  verifierId: uuid('verifier_id').references(() => users.userId),
  attachmentRequired: boolean('attachment_required').default(false),
  frequency: varchar('frequency', { length: 50 }),
  status: varchar('status', { length: 50 }).default('Pending'),
  dueDate: date('due_date'),
  proofFileUrl: text('proof_file_url'),
  completedAt: timestamp('completed_at'),
  revisionCount: integer('revision_count').default(0),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export const checklistMaster = pgTable('checklist_master', {
  id: uuid('id').primaryKey().defaultRandom(),
  delegationId: uuid('delegation_id').references(() => delegations.id),
  itemName: text('item_name').notNull(),
  assignerId: uuid('assigner_id').references(() => users.userId),
  doerId: uuid('doer_id').references(() => users.userId),
  priority: varchar('priority', { length: 50 }),
  category: varchar('category', { length: 100 }),
  verificationRequired: boolean('verification_required').default(false),
  verifierId: uuid('verifier_id').references(() => users.userId),
  attachmentRequired: boolean('attachment_required').default(false),
  frequency: varchar('frequency', { length: 50 }),
  fromDate: date('from_date'),
  dueDate: date('due_date'),
  weeklyDays: jsonb('weekly_days'),
  selectedDates: jsonb('selected_dates'),
  intervalDays: integer('interval_days'),
  occurEveryMode: varchar('occur_every_mode', { length: 50 }),
  occurValue: integer('occur_value'),
  occurDays: jsonb('occur_days'),
  occurDates: jsonb('occur_dates'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export const checklist = pgTable('checklist', {
  id: uuid('id').primaryKey().defaultRandom(),
  masterId: uuid('master_id').references(() => checklistMaster.id),
  delegationId: uuid('delegation_id').references(() => delegations.id),
  itemName: text('item_name').notNull(),
  assignerId: uuid('assigner_id').references(() => users.userId),
  doerId: uuid('doer_id').references(() => users.userId),
  priority: varchar('priority', { length: 50 }),
  category: varchar('category', { length: 100 }),
  verificationRequired: boolean('verification_required').default(false),
  verifierId: uuid('verifier_id').references(() => users.userId),
  attachmentRequired: boolean('attachment_required').default(false),
  frequency: varchar('frequency', { length: 50 }),
  status: varchar('status', { length: 50 }).default('Pending'),
  dueDate: date('due_date'),
  proofFileUrl: text('proof_file_url'),
  completedAt: timestamp('completed_at'),
  revisionCount: integer('revision_count').default(0),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export const holidays = pgTable('holidays', {
  id: uuid('id').primaryKey().defaultRandom(),
  name: varchar('name', { length: 255 }).notNull(),
  date: date('date').notNull(),
  createdBy: uuid('created_by'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export const categories = pgTable('categories', {
  id: uuid('id').primaryKey().defaultRandom(),
  name: varchar('name', { length: 255 }).notNull(),
  color: varchar('color', { length: 50 }).notNull(),
  createdBy: uuid('created_by').references(() => users.userId),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

export const groups = pgTable('groups', {
  groupId: uuid('group_id').primaryKey().defaultRandom(),
  name: varchar('name', { length: 255 }).notNull(),
  description: text('description'),
  imageUrl: text('image_url'),
  createdBy: uuid('created_by').references(() => users.userId).notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export const groupMembers = pgTable('group_members', {
  id: uuid('id').primaryKey().defaultRandom(),
  groupId: uuid('group_id').references(() => groups.groupId).notNull(),
  userId: uuid('user_id').references(() => users.userId).notNull(),
  addedBy: uuid('added_by').references(() => users.userId).notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

export const tickets = pgTable('tickets', {
  id: uuid('id').primaryKey().defaultRandom(),
  title: varchar('title', { length: 255 }).notNull(),
  description: text('description').notNull(),
  category: varchar('category', { length: 100 }).notNull(), // Report An Error, Give Feedback, Billing/Subscription, Delete My Account
  subCategory: varchar('sub_category', { length: 100 }).notNull(), // Tasks Delegation, My Team, Intranet, Leaves, Attendance, Other
  priority: varchar('priority', { length: 50 }).default('Medium'), // Low, Medium, High
  status: varchar('status', { length: 50 }).default('Open'), // Open, InProgress, Resolved, Closed
  raisedBy: uuid('raised_by').references(() => users.userId).notNull(),
  assignedTo: uuid('assigned_to').references(() => users.userId),
  screenshotUrls: jsonb('screenshot_urls'), // Array of base64 strings
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// User Settings - Company info
export const userSettings = pgTable('user_settings', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').references(() => users.userId).notNull().unique(),
  companyName: varchar('company_name', { length: 255 }),
  businessIndustry: varchar('business_industry', { length: 100 }),
  companySize: varchar('company_size', { length: 50 }),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Task Update Settings - Mandatory fields
export const taskUpdateSettings = pgTable('task_update_settings', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').references(() => users.userId).notNull().unique(),
  remarksRequired: boolean('remarks_required').default(true),
  attachmentsRequired: boolean('attachments_required').default(false),
  imagesRequired: boolean('images_required').default(false),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Notification Settings - User notification preferences
export const notificationSettings = pgTable('notification_settings', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').references(() => users.userId).notNull().unique(),
  informaticsNotifications: boolean('informatics_notifications').default(true),
  emailNotifications: boolean('email_notifications').default(true),
  dailyReminder: boolean('daily_reminder').default(true),
  emailReminders: boolean('email_reminders').default(true),
  taskReminderTime: varchar('task_reminder_time', { length: 5 }).default('09:00'),
  weeklyOnly: boolean('weekly_only').default(false),
  reminderDays: jsonb('reminder_days'), // ["Monday", "Wednesday", etc]
  notificationChannels: jsonb('notification_channels'), // Role-based notification settings
  notificationFrequency: jsonb('notification_frequency'), // Role-based frequency settings
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Export Logs - Track task exports
export const exportLogs = pgTable('export_logs', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').references(() => users.userId).notNull(),
  dateRange: varchar('date_range', { length: 100 }),
  assignedTo: jsonb('assigned_to'), // Array of user IDs
  assignedBy: jsonb('assigned_by'), // Array of user IDs
  taskType: jsonb('task_type'), // Array of task types
  filePath: text('file_path'),
  fileSize: integer('file_size'),
  exportFormat: varchar('export_format', { length: 20 }), // csv, excel, pdf
  createdAt: timestamp('created_at').defaultNow().notNull(),
  expiresAt: timestamp('expires_at').notNull(), // Auto-delete after 60 days
});

// Roles - Custom and default roles
export const roles = pgTable('roles', {
  id: uuid('id').primaryKey().defaultRandom(),
  name: varchar('name', { length: 100 }).notNull().unique(),
  description: text('description'),
  isDefault: boolean('is_default').default(false),
  createdBy: uuid('created_by').references(() => users.userId),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Role Permissions - Permissions for each role
export const rolePermissions = pgTable('role_permissions', {
  id: uuid('id').primaryKey().defaultRandom(),
  roleId: uuid('role_id').references(() => roles.id).notNull(),
  action: varchar('action', { length: 100 }).notNull(), // Create, Edit, View, Delete, Import Task, Export Task
  allowed: boolean('allowed').default(false),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});
