import { db } from './src/db/index.js';
import { users } from './src/db/schema.js';
import { eq } from 'drizzle-orm';
import bcrypt from 'bcryptjs';

async function updatePass() {
    try {
        const hashedPassword = await bcrypt.hash('123456', 10);
        await db.update(users).set({ password: hashedPassword }).where(eq(users.workEmail, 'arpit@gmail.com'));
        console.log('Password updated successfully for arpit@gmail.com');
        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

updatePass();
