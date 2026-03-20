import { pgTable, text, timestamp, uuid, numeric, date, varchar, integer, boolean, jsonb } from 'drizzle-orm/pg-core';

export const roles = pgTable('roles', {
  id: uuid('id').primaryKey().defaultRandom(),
  name: varchar('name', { length: 255 }).notNull().unique(),
  description: text('description'),
  permissions: jsonb('permissions'),
  isCustom: boolean('is_custom').default(false).notNull(),
  createdBy: uuid('created_by'), // Allowed to be null for default roles
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

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
  manager: varchar('manager', { length: 255 }), // Keeping for backward compatibility or as name
  reportingManagerId: uuid('reporting_manager_id').references(() => users.userId),
  contract: text('contract'),
  maritalStatus: varchar('marital_status', { length: 50 }),
  anniversaryDate: date('anniversary_date'),
  gender: varchar('gender', { length: 20 }),
  address: text('address'),
  city: varchar('city', { length: 100 }),
  state: varchar('state', { length: 100 }),
  nationality: varchar('nationality', { length: 100 }),
  theme: varchar('theme', { length: 20 }).default('light'),
  taskAccess: boolean('task_access').default(true).notNull(),
  leaveAccess: boolean('leave_access').default(true).notNull(),
  status: varchar('status', { length: 20 }).default('active').notNull(),
  addedBy: uuid('added_by'), // Track who added the user to filter My Team
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
  dueDate: timestamp('due_date'),
  voiceNoteUrl: text('voice_note_url'),
  referenceDocs: text('reference_docs'),
  tags: jsonb('tags'),
  checklistItems: jsonb('checklist_items'),
  evidenceRequired: boolean('evidence_required').default(false),
  evidenceUrl: text('evidence_url'),
  revisionCount: integer('revision_count').default(0),
  inLoopIds: jsonb('in_loop_ids'),
  groupId: uuid('group_id').references(() => groups.groupId),
  parentId: uuid('parent_id').references(() => delegations.id), // support subtasks
  deletedAt: timestamp('deleted_at'), // soft delete — null means active
  deletedBy: uuid('deleted_by').references(() => users.userId), // who deleted
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export const revisionHistory = pgTable('revision_history', {
  id: uuid('id').primaryKey().defaultRandom(),
  delegationId: uuid('delegation_id').references(() => delegations.id).notNull(),
  oldDueDate: timestamp('old_due_date'),
  newDueDate: timestamp('new_due_date'),
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
  role: varchar('role', { length: 50 }).notNull(), // TEAM MEMBER, MANAGER, ADMIN
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
  fromDate: timestamp('from_date'),
  dueDate: timestamp('due_date'),
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

export const checklistMaster = pgTable('checklist_master', {
  id: uuid('id').primaryKey().defaultRandom(),
  delegationId: uuid('delegation_id').references(() => delegations.id),
  taskTitle: varchar('task_title', { length: 255 }).notNull(),
  description: text('description'),
  assignerId: uuid('assigner_id').references(() => users.userId),
  doerId: uuid('doer_id').references(() => users.userId),
  priority: varchar('priority', { length: 50 }),
  category: varchar('category', { length: 100 }),
  verificationRequired: boolean('verification_required').default(false),
  verifierId: uuid('verifier_id').references(() => users.userId),
  attachmentRequired: boolean('attachment_required').default(false),
  voiceNoteUrl: text('voice_note_url'),
  referenceDocs: text('reference_docs'),
  tags: jsonb('tags'),
  inLoopIds: jsonb('in_loop_ids'),
  checklistItems: jsonb('checklist_items'),
  frequency: varchar('frequency', { length: 50 }),
  fromDate: timestamp('from_date'),
  dueDate: timestamp('due_date'),
  weeklyDays: jsonb('weekly_days'),
  selectedDates: jsonb('selected_dates'),
  intervalDays: integer('interval_days'),
  occurEveryMode: varchar('occur_every_mode', { length: 50 }),
  occurValue: integer('occur_value'),
  occurDays: jsonb('occur_days'),
  occurDates: jsonb('occur_dates'),
  groupId: uuid('group_id').references(() => groups.groupId),
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

export const tags = pgTable('tags', {
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

export const taskTemplates = pgTable('task_templates', {
  id: uuid('id').primaryKey().defaultRandom(),
  title: varchar('title', { length: 255 }).notNull(),
  description: text('description'),
  category: varchar('category', { length: 100 }),
  priority: varchar('priority', { length: 50 }),
  frequency: varchar('frequency', { length: 50 }).default('Once'),
  checklistItems: jsonb('checklist_items'), // Array of strings or {text, completed}
  createdBy: uuid('created_by').references(() => users.userId).notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export const activities = pgTable('activities', {
  id: uuid('id').primaryKey().defaultRandom(),
  type: varchar('type', { length: 50 }).notNull(), // task_created, subtask_created, status_change, remark, deleted, restored
  title: varchar('title', { length: 255 }).notNull(), 
  description: text('description'),
  userId: uuid('user_id').references(() => users.userId).notNull(),
  relatedId: uuid('related_id'), // usually delegationId
  relatedType: varchar('related_type', { length: 50 }), // task, group, holiday
  metadata: jsonb('metadata'), // store old/new values, etc.
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

export const holidays = pgTable('holidays', {
  id: uuid('id').primaryKey().defaultRandom(),
  name: varchar('name', { length: 255 }).notNull(),
  date: date('date').notNull(),
  createdBy: uuid('created_by').references(() => users.userId).notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

export const deletedAccounts = pgTable('deleted_accounts', {
  id: uuid('id').primaryKey().defaultRandom(),
  originalUserId: uuid('original_user_id'),
  firstName: varchar('first_name', { length: 255 }),
  lastName: varchar('last_name', { length: 255 }),
  workEmail: varchar('work_email', { length: 255 }),
  mobileNumber: varchar('mobile_number', { length: 20 }),
  role: varchar('role', { length: 50 }),
  designation: varchar('designation', { length: 100 }),
  department: varchar('department', { length: 100 }),
  deletedBy: uuid('deleted_by'), // ID of the admin who requested deletion
  deletedAt: timestamp('deleted_at').defaultNow().notNull(),
});
export const notificationPreferences = pgTable('notification_preferences', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').references(() => users.userId).notNull().unique(),
  whatsappNotifications: boolean('whatsapp_notifications').default(false).notNull(),
  emailNotifications: boolean('email_notifications').default(false).notNull(),
  timezone: varchar('timezone', { length: 100 }).default('Asia/Kolkata').notNull(),
  dailyReminderTime: varchar('daily_reminder_time', { length: 5 }).default('09:00'), // HH:mm format
  whatsappReminders: boolean('whatsapp_reminders').default(false).notNull(),
  emailReminders: boolean('email_reminders').default(false).notNull(),
  dailyTaskReport: boolean('daily_task_report').default(false).notNull(),
  weeklyOffs: jsonb('weekly_offs').default(['Sunday']).notNull(), // Array of days
  notificationChannels: jsonb('notification_channels').default({
    newTask: { admin: true, manager: true, member: true },
    taskEdit: { admin: true, manager: true, member: true },
    taskComment: { admin: true, manager: true, member: true },
    taskInProgress: { admin: true, manager: true, member: true },
    taskComplete: { admin: true, manager: true, member: true },
    taskReOpen: { admin: true, manager: true, member: true }
  }).notNull(),
  notificationFrequency: jsonb('notification_frequency').default({
    admin: {
      newTask: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
      taskEdit: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
      taskComment: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
      taskInProgress: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
      taskComplete: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
      taskReOpen: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
      dailyPendingReminders: { once: true, daily: false, weekly: false, monthly: false, yearly: false }
    },
    manager: {
      newTask: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
      taskEdit: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
      taskComment: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
      taskInProgress: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
      taskComplete: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
      taskReOpen: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
      dailyPendingReminders: { once: true, daily: false, weekly: false, monthly: false, yearly: false }
    },
    member: {
      newTask: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
      taskEdit: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
      taskComment: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
      taskInProgress: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
      taskComplete: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
      taskReOpen: { once: true, daily: false, weekly: false, monthly: false, yearly: false },
      dailyPendingReminders: { once: true, daily: false, weekly: false, monthly: false, yearly: false }
    }
  }),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export const taskReminders = pgTable('task_reminders', {
  id: uuid('id').primaryKey().defaultRandom(),
  delegationId: uuid('delegation_id').references(() => delegations.id).notNull(),
  type: varchar('type', { length: 50 }).notNull(), // 'email', 'whatsapp', 'mobile'
  timeValue: integer('time_value').notNull(),
  timeUnit: varchar('time_unit', { length: 50 }).notNull(), // 'minutes', 'hours', 'days'
  triggerType: varchar('trigger_type', { length: 50 }).notNull(), // 'before', 'after'
  reminderTime: timestamp('reminder_time').notNull(),
  isSent: boolean('is_sent').default(false).notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export const notificationTemplates = pgTable('notification_templates', {
  id: uuid('id').primaryKey().defaultRandom(),
  eventName: varchar('event_name', { length: 50 }).notNull(), // newTask, taskEdit, taskComment, taskInProgress, taskComplete, taskReOpen, dailyPendingReminders
  channel: varchar('channel', { length: 20 }).notNull(), // whatsapp, email
  subject: text('subject'),
  body: text('body').notNull(),
  isActive: boolean('is_active').default(true).notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

