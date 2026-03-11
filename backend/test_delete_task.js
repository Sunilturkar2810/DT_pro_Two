import { db } from './src/db/index.js';
import { delegations, checklist, revisionHistory, remarkHistory } from './src/db/schema.js';
import { eq } from 'drizzle-orm';

async function testDelete() {
    try {
        const taskId = 'aafa9574-ecf6-4729-bd71-9bfe63a9b004';
        
        // When deleting a task, you often need to delete its related records first
        // due to foreign key constraints
        
        console.log('1. Trying to delete checklist items...');
        await db.delete(checklist).where(eq(checklist.delegationId, taskId));
        
        console.log('2. Trying to delete remarks...');
        await db.delete(remarkHistory).where(eq(remarkHistory.delegationId, taskId));
        
        console.log('3. Trying to delete revisions...');
        await db.delete(revisionHistory).where(eq(revisionHistory.delegationId, taskId));
        
        console.log('4. Trying to delete task...');
        await db.delete(delegations).where(eq(delegations.id, taskId));

        console.log('✅ Delete Successful!');
        process.exit(0);
    } catch(e) {
        console.error('❌ Delete Failed:', e.message);
        process.exit(1);
    }
}
testDelete();
