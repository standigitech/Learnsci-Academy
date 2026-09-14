import pg from "pg";
import { env } from "./config/env.js";
const { Pool } = pg;
export const pool = new Pool({ connectionString: env.db, max: 15, ssl: env.nodeEnv === "production" ? { rejectUnauthorized: false } : false });
export async function query(text, params){ return pool.query(text, params); }
