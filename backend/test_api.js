// Simple test - just fetch delegation by ID and see what error occurs
import { db } from './src/db/index.js';
import { delegations, remarkHistory } from './src/db/schema.js';
import { eq, desc } from 'drizzle-orm';

const id = '22c136fd-b387-4a43-aea5-fcb1e39b5471';

try {
    process.stdout.write('Step 1: Fetching delegation...\n');
    const [delegation] = await db.select().from(delegations).where(eq(delegations.id, id));
    process.stdout.write(`Step 1 OK: ${delegation ? delegation.taskTitle : 'NOT FOUND'}\n`);

    if (!delegation) { process.exit(0); }

    process.stdout.write('Step 2: Fetching remarks...\n');
    const remarks = await db.select().from(remarkHistory).where(eq(remarkHistory.delegationId, id)).orderBy(desc(remarkHistory.createdAt));
    process.stdout.write(`Step 2 OK: ${remarks.length} remarks\n`);
    if(remarks.length > 0) {
        process.stdout.write(`First remark keys: ${Object.keys(remarks[0]).join(', ')}\n`);
        process.stdout.write(`First remark: ${remarks[0].remark}\n`);
    }

    process.stdout.write('Step 3: Fetching checklist...\n');
    // Use raw SQL to avoid any ORM issues
    const { neon } = await import('@neondatabase/serverless');
    const sql = neon(process.env.DATABASE_URL);
    const checklistRows = await sql`SELECT * FROM checklist WHERE delegation_id = ${id}`;
    process.stdout.write(`Step 3 OK: ${checklistRows.length} checklist items\n`);

    process.stdout.write('ALL STEPS OK!\n');
    process.stdout.write(`voiceNoteUrl: ${delegation.voiceNoteUrl}\n`);
    process.stdout.write(`referenceDocs: ${delegation.referenceDocs}\n`);
} catch(e) {
    process.stdout.write(`CAUGHT ERROR: ${e.message}\n`);
}
process.exit(0);
