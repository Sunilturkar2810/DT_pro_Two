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
