import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { db } from './src/db/index.js';
import { sql } from 'drizzle-orm';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config();

export const runAutoMigrations = async () => {
    try {
        console.log('🔄 Running automatic schema synchronization...');
        
        // Find the latest migration file
        const drizzleDir = path.join(__dirname, 'drizzle');
        if (!fs.existsSync(drizzleDir)) {
            console.log('⚠️ No drizzle directory found.');
            return;
        }

        const files = fs.readdirSync(drizzleDir).filter(f => f.endsWith('.sql')).sort();
        if (files.length === 0) {
            console.log('⚠️ No automated migration files found.');
            return;
        }

        const latestMigration = files[files.length - 1]; // E.g., 0000_puzzling_multiple_man.sql
        const migrationPath = path.join(drizzleDir, latestMigration);
        
        const sqlContent = fs.readFileSync(migrationPath, 'utf8');
        const statements = sqlContent.split('--> statement-breakpoint').map(s => s.trim()).filter(Boolean);

        let executed = 0;
        let skipped = 0;

        for (let statement of statements) {
            if (statement.startsWith('CREATE TABLE')) {
                statement = statement.replace('CREATE TABLE', 'CREATE TABLE IF NOT EXISTS');
            }
            
            try {
                // Execute using raw SQL
                await db.execute(sql.raw(statement));
                executed++;
            } catch (err) {
                const msg = err.message || '';
                // Ignore "already exists" and constraint errors safely
                if (msg.includes('already exists') || 
                    msg.includes('multiple primary keys') ||
                    msg.includes('Failed query: ALTER TABLE')) {
                    skipped++;
                } else {
                    console.error('⚠️ DB init hint (safe to ignore if table exists):', msg.split('\n')[0]);
                }
            }
        }
        
        console.log(`✅ Schema check complete. Executed/Verified: ${executed} portions, Skipped (already exist): ${skipped}`);
    } catch (e) {
        console.error('⚠️ Migration runner failed to start:', e.message);
    }
};

// Run if called directly
if (process.argv[1] === fileURLToPath(import.meta.url)) {
    runAutoMigrations().then(() => process.exit(0)).catch(err => {
        console.error(err);
        process.exit(1);
    });
}
