import fs from "node:fs";import path from "node:path";import {fileURLToPath} from "node:url";import {pool} from "../src/db.js";
const __dirname=path.dirname(fileURLToPath(import.meta.url));const sql=fs.readFileSync(path.join(__dirname,"../../database/schema.sql"),"utf8");await pool.query(sql);console.log("Database migrated");await pool.end();
