import { db } from './src/db/index.js';
import fs from 'fs';
async function run() {
  try {
    const res = await db.execute("SELECT column_name FROM information_schema.columns WHERE table_name='delegations'");
    fs.writeFileSync('cols.json', JSON.stringify(res.rows || res, null, 2));
  } catch (e) {
    console.error(e);
  } finally {
    process.exit(0);
  }
}
run();
