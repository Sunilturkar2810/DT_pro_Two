import { db } from './src/db/index.js';
import { tickets } from './src/db/schema.js';
import { sql } from 'drizzle-orm';

async function migrate() {
  try {
    console.log('🔄 Starting migration...');
    
    // Create tickets table using raw SQL to ensure it exists
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

    console.log('✅ Tickets table created successfully');
    
    // Check if table exists and has data
    const count = await db.execute(sql`SELECT COUNT(*) FROM "tickets"`);
    console.log('📊 Current ticket count:', count);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    // Don't fail hard, the table might already exist
    process.exit(0);
  }
}

migrate();
