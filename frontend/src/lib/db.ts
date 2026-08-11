import { Pool } from 'pg';

// Create a new pool instance using the database URL from the environment variables
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  // Optionally, you can set additional parameters like max connections, etc.
  max: 10, // Max number of connections
  idleTimeoutMillis: 30000,
});

export default pool;
