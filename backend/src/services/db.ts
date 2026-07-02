import path from 'path';
import dotenv from 'dotenv';
import { Pool } from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';

// Load environmental variables
dotenv.config({ path: path.resolve(process.cwd(), '.env') });

// Initialize the native Postgres Pool connection
const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);

// Pass the adapter directly into the Prisma Client
const prisma = new PrismaClient({ adapter });

export default prisma;