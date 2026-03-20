import { neon } from '@neondatabase/serverless';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load env from the backend root
dotenv.config({ path: join(__dirname, '..', '.env') });

if (!process.env.DATABASE_URL) {
    console.error('DATABASE_URL not found! Env vars:', Object.keys(process.env).join(', '));
    process.exit(1);
}

const sql = neon(process.env.DATABASE_URL);

try {
    const result = await sql`
        CREATE TABLE IF NOT EXISTS deleted_accounts (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            original_user_id UUID,
            first_name VARCHAR(255),
            last_name VARCHAR(255),
            work_email VARCHAR(255),
            mobile_number VARCHAR(20),
            role VARCHAR(50),
            designation VARCHAR(100),
            department VARCHAR(100),
            deleted_by UUID,
            deleted_at TIMESTAMP DEFAULT NOW() NOT NULL
        );
    `;
    console.log('✅ Table "deleted_accounts" created successfully!');
} catch (err) {
    console.error('❌ Error creating table:', err.message);
    process.exit(1);
}
process.exit(0);
