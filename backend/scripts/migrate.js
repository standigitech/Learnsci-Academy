import "dotenv/config";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import pg from "pg";

const { Pool } = pg;

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const schemaPath = path.join(
  __dirname,
  "..",
  "..",
  "database",
  "schema.sql"
);

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  console.error("❌ DATABASE_URL is not defined.");
  process.exit(1);
}

const pool = new Pool({
  connectionString,

  ssl: {
    rejectUnauthorized: false,
  },

  max: 1,

  connectionTimeoutMillis: 15000,

  idleTimeoutMillis: 30000,

  statement_timeout: 120000,

  query_timeout: 120000,
});

async function runMigration() {
  let client;

  try {
    console.log("========================================");
    console.log("LearnSci Database Migration");
    console.log("========================================");

    console.log("\nReading schema:");
    console.log(schemaPath);

    if (!fs.existsSync(schemaPath)) {
      throw new Error(`Schema file not found: ${schemaPath}`);
    }

    const sql = fs.readFileSync(schemaPath, "utf8");

    console.log(`Schema size: ${sql.length} characters`);

    console.log("\nConnecting to Neon PostgreSQL...");

    client = await pool.connect();

    const connectionTest = await client.query(`
      SELECT
        NOW() AS time,
        current_database() AS database
    `);

    console.log("✅ Connected successfully.");
    console.log("Database:", connectionTest.rows[0].database);
    console.log("Time:", connectionTest.rows[0].time);

    console.log("\nApplying database schema...");

    await client.query("BEGIN");

    await client.query(sql);

    await client.query("COMMIT");

    console.log("\n========================================");
    console.log("✅ Migration completed successfully!");
    console.log("========================================");
  } catch (error) {
    if (client) {
      try {
        await client.query("ROLLBACK");
      } catch {
        // Ignore rollback errors
      }
    }

    console.error("\n❌ Migration failed.");
    console.error(error);

    process.exitCode = 1;
  } finally {
    if (client) {
      client.release();
    }

    await pool.end();
  }
}

runMigration();