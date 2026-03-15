import buildApp from './app.js';
import dotenv from 'dotenv';
import { initCron } from './utils/cron.js';
import { db } from './db/index.js';
import { sql } from 'drizzle-orm';

dotenv.config();

const PORT = process.env.PORT || 5000;

const app = buildApp({
    logger: {
        level: 'info',
        transport: {
            target: 'pino-pretty'
        }
    }
});

// Initialize database tables
const initDatabase = async () => {
    try {
        console.log('🔄 Checking database tables...');
        
        // Create tickets table if it doesn't exist
        await db.execute(sql`
            CREATE TABLE IF NOT EXISTS "tickets" (
                "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
                "title" varchar(255) NOT NULL,
                "description" text NOT NULL,
                "category" varchar(100) NOT NULL,
                "sub_category" varchar(100) NOT NULL,
                "priority" varchar(50) DEFAULT 'Medium',
                "status" varchar(50) DEFAULT 'Open',
                "raised_by" uuid NOT NULL REFERENCES "users"("user_id") ON DELETE CASCADE,
                "assigned_to" uuid REFERENCES "users"("user_id") ON DELETE SET NULL,
                "screenshot_urls" jsonb DEFAULT '[]'::jsonb,
                "created_at" timestamp DEFAULT NOW() NOT NULL,
                "updated_at" timestamp DEFAULT NOW() NOT NULL
            )
        `);

        // Create user_settings table if it doesn't exist
        await db.execute(sql`
            CREATE TABLE IF NOT EXISTS "user_settings" (
                "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
                "user_id" uuid NOT NULL UNIQUE REFERENCES "users"("user_id") ON DELETE CASCADE,
                "company_name" varchar(255),
                "business_industry" varchar(100),
                "company_size" varchar(50),
                "created_at" timestamp DEFAULT NOW() NOT NULL,
                "updated_at" timestamp DEFAULT NOW() NOT NULL
            )
        `);

        // Create task_update_settings table if it doesn't exist
        await db.execute(sql`
            CREATE TABLE IF NOT EXISTS "task_update_settings" (
                "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
                "user_id" uuid NOT NULL UNIQUE REFERENCES "users"("user_id") ON DELETE CASCADE,
                "remarks_required" boolean DEFAULT true,
                "attachments_required" boolean DEFAULT false,
                "images_required" boolean DEFAULT false,
                "created_at" timestamp DEFAULT NOW() NOT NULL,
                "updated_at" timestamp DEFAULT NOW() NOT NULL
            )
        `);

        // Create notification_settings table if it doesn't exist
        await db.execute(sql`
            CREATE TABLE IF NOT EXISTS "notification_settings" (
                "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
                "user_id" uuid NOT NULL UNIQUE REFERENCES "users"("user_id") ON DELETE CASCADE,
                "informatics_notifications" boolean DEFAULT true,
                "email_notifications" boolean DEFAULT true,
                "daily_reminder" boolean DEFAULT true,
                "email_reminders" boolean DEFAULT true,
                "task_reminder_time" varchar(5) DEFAULT '09:00',
                "weekly_only" boolean DEFAULT false,
                "reminder_days" jsonb DEFAULT '[]'::jsonb,
                "notification_channels" jsonb DEFAULT '{}'::jsonb,
                "notification_frequency" jsonb DEFAULT '{}'::jsonb,
                "created_at" timestamp DEFAULT NOW() NOT NULL,
                "updated_at" timestamp DEFAULT NOW() NOT NULL
            )
        `);

        // Create export_logs table if it doesn't exist
        await db.execute(sql`
            CREATE TABLE IF NOT EXISTS "export_logs" (
                "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
                "user_id" uuid NOT NULL REFERENCES "users"("user_id") ON DELETE CASCADE,
                "date_range" varchar(100),
                "assigned_to" jsonb DEFAULT '[]'::jsonb,
                "assigned_by" jsonb DEFAULT '[]'::jsonb,
                "task_type" jsonb DEFAULT '[]'::jsonb,
                "file_path" text,
                "file_size" integer,
                "export_format" varchar(20),
                "created_at" timestamp DEFAULT NOW() NOT NULL,
                "expires_at" timestamp NOT NULL
            )
        `);

        // Create roles table if it doesn't exist
        await db.execute(sql`
            CREATE TABLE IF NOT EXISTS "roles" (
                "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
                "name" varchar(100) NOT NULL UNIQUE,
                "description" text,
                "is_default" boolean DEFAULT false,
                "created_by" uuid REFERENCES "users"("user_id") ON DELETE SET NULL,
                "created_at" timestamp DEFAULT NOW() NOT NULL,
                "updated_at" timestamp DEFAULT NOW() NOT NULL
            )
        `);

        // Create role_permissions table if it doesn't exist
        await db.execute(sql`
            CREATE TABLE IF NOT EXISTS "role_permissions" (
                "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
                "role_id" uuid NOT NULL REFERENCES "roles"("id") ON DELETE CASCADE,
                "action" varchar(100) NOT NULL,
                "allowed" boolean DEFAULT false,
                "created_at" timestamp DEFAULT NOW() NOT NULL,
                "updated_at" timestamp DEFAULT NOW() NOT NULL
            )
        `);

        // Insert default roles if not already present
        const existingRoles = await db.execute(sql`SELECT COUNT(*) as count FROM "roles" WHERE "is_default" = true`);
        if (existingRoles[0].count === 0) {
            const defaultRoles = ['Admin', 'Manager', 'Team Member'];
            for (const role of defaultRoles) {
                await db.execute(sql`
                    INSERT INTO "roles" ("name", "is_default", "created_at", "updated_at")
                    VALUES (${role}, true, NOW(), NOW())
                    ON CONFLICT (name) DO NOTHING
                `);
            }
            console.log('✅ Default roles created');
        }
        
        console.log('✅ Database tables initialized');
    } catch (error) {
        console.error('⚠️ Database initialization warning:', error.message);
        // Don't fail the server startup if table already exists
    }
};

const start = async () => {
    try {
        // Initialize database
        await initDatabase();

        // Initialize cron jobs
        initCron();

        // Start server
        await app.listen({ port: Number(PORT), host: '0.0.0.0' });
        console.log(`Server started on port ${PORT}`);
    } catch (err) {
        app.log.error(err);
        process.exit(1);
    }
};

start();
