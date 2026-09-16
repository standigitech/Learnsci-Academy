import "dotenv/config";
import { Pool } from "pg";
import { env } from "./config/env.js";

// Neon requires SSL. We enable rejectUnauthorized: false for hosted environments
// or fallback cleanly if connecting to local development without SSL.
export const pool = new Pool({
  connectionString: env.DATABASE_URL,
  ssl: env.nodeEnv === "production" || env.DATABASE_URL?.includes("neon.tech")
    ? { rejectUnauthorized: false }
    : false,
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

// Test connection and log state on startup
pool.on("connect", () => {
  console.log("Connected to Neon PostgreSQL database");
});

pool.on("error", (err) => {
  console.error("Unexpected error on idle database client:", err);
  process.exit(-1);
});

export const query = (text, params) => pool.query(text, params);
