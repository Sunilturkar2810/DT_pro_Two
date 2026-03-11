import { db } from './src/db/index.js';
db.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'delegations'")
  .then(c => console.log(c.rows.map(r => r.column_name).join(', ')))
  .catch(console.error)
  .finally(() => process.exit(0));
