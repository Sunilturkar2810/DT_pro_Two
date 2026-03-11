// Create checklist and checklist_master tables if they don't exist
import { neon } from '@neondatabase/serverless';
import dotenv from 'dotenv';
dotenv.config();

const sql = neon(process.env.DATABASE_URL);

const createTables = async () => {
    try {
        // Check if checklist table exists
        const exists = await sql`
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_name = 'checklist'
            )
        `;
        
        if (exists[0].exists) {
            process.stdout.write('checklist table ALREADY EXISTS\n');
        } else {
            process.stdout.write('Creating checklist table...\n');
            await sql`
                CREATE TABLE IF NOT EXISTS checklist (
                    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    master_id UUID REFERENCES checklist_master(id),
                    delegation_id UUID REFERENCES delegations(id),
                    item_name TEXT NOT NULL,
                    assigner_id UUID REFERENCES users(user_id),
                    doer_id UUID REFERENCES users(user_id),
                    priority VARCHAR(50),
                    category VARCHAR(100),
                    verification_required BOOLEAN DEFAULT false,
                    verifier_id UUID REFERENCES users(user_id),
                    attachment_required BOOLEAN DEFAULT false,
                    frequency VARCHAR(50),
                    status VARCHAR(50) DEFAULT 'Pending',
                    due_date DATE,
                    proof_file_url TEXT,
                    completed_at TIMESTAMP,
                    revision_count INTEGER DEFAULT 0,
                    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
                    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
                )
            `;
            process.stdout.write('checklist table CREATED!\n');
        }

        // Check checklist_master
        const masterExists = await sql`
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_name = 'checklist_master'
            )
        `;
        
        if (masterExists[0].exists) {
            process.stdout.write('checklist_master table ALREADY EXISTS\n');
        } else {
            process.stdout.write('Creating checklist_master table...\n');
            await sql`
                CREATE TABLE IF NOT EXISTS checklist_master (
                    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    delegation_id UUID REFERENCES delegations(id),
                    item_name TEXT NOT NULL,
                    assigner_id UUID REFERENCES users(user_id),
                    doer_id UUID REFERENCES users(user_id),
                    priority VARCHAR(50),
                    category VARCHAR(100),
                    verification_required BOOLEAN DEFAULT false,
                    verifier_id UUID REFERENCES users(user_id),
                    attachment_required BOOLEAN DEFAULT false,
                    frequency VARCHAR(50),
                    from_date DATE,
                    due_date DATE,
                    weekly_days JSONB,
                    selected_dates JSONB,
                    interval_days INTEGER,
                    occur_every_mode VARCHAR(50),
                    occur_value INTEGER,
                    occur_days JSONB,
                    occur_dates JSONB,
                    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
                    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
                )
            `;
            process.stdout.write('checklist_master table CREATED!\n');
        }
        
        process.stdout.write('DONE!\n');
    } catch(e) {
        process.stdout.write(`ERROR: ${e.message}\n`);
    }
    process.exit(0);
};

createTables();
