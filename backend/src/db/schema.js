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
  // asset: varchar('asset', { length: 255 }), // Removed since not in DB
  revisionCount: integer('revision_count').default(0),
  inLoopIds: jsonb('in_loop_ids'),
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
