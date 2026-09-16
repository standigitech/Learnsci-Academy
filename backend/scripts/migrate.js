import "dotenv/config";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { pool } from "../src/db.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

async function runMigration() {
  try {
    const schemaPath = path.join(
      __dirname,
      "..",
      "..",
      "database",
      "schema.sql"
    );

    console.log("Reading schema:", schemaPath);

    const sql = fs.readFileSync(schemaPath, "utf-8");

    console.log("Applying database schema...");

    await pool.query(sql);

    console.log("Migration completed successfully!");
  } catch (err) {
    console.error("Migration failed:", err);
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
}

runMigration();