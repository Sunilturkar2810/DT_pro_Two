import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import * as schema from './schema.js';
import dotenv from 'dotenv';

dotenv.config();

if (!process.env.DATABASE_URL) {
    throw new Error('DATABASE_URL is not defined in environment variables');
}

// Use postgres.js for a more robust TCP connection
const queryClient = postgres(process.env.DATABASE_URL, {
    ssl: 'require',
    max: 1, // Stay safe with cluster (12 workers * 1 = 12 connections)
    idle_timeout: 20,
    connect_timeout: 30, 
});

export const db = drizzle(queryClient, { schema });

