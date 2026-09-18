import { z } from "zod";
import { query } from "../db.js";
import {
  hashPassword,
  comparePassword,
  signToken,
} from "../utils/auth.js";

const registerSchema = z.object({
  name: z.string().min(2).max(100),
  email: z.string().email(),
  password: z.string().min(8),
  confirmPassword: z.string().min(8),
});

export async function register(req, res) {
  try {
    const body = registerSchema.parse(req.body);

    if (body.password !== body.confirmPassword) {
      return res.status(400).json({
        message: "Passwords do not match",
      });
    }

    const email = body.email.toLowerCase();

    const exists = await query(
      "SELECT id FROM users WHERE email = $1",
      [email]
    );

    if (exists.rows[0]) {
      return res.status(409).json({
        message: "Email already registered",
      });
    }

    const role = await query(
      "SELECT id FROM roles WHERE name = 'learner'"
    );

    if (!role.rows[0]) {
      return res.status(500).json({
        message: "Learner role is not configured",
      });
    }

    const passwordHash = await hashPassword(body.password);

    const { rows } = await query(
      `
      INSERT INTO users (
        name,
        email,
        password_hash,
        role_id
      )
      VALUES ($1, $2, $3, $4)
      RETURNING id, name, email
      `,
      [
        body.name,
        email,
        passwordHash,
        role.rows[0].id,
      ]
    );

    const user = {
      ...rows[0],
      role: "learner",
      hasActiveSubscription: false,
    };

    return res.status(201).json({
      token: signToken(user),
      user,
    });
  } catch (e) {
    return res.status(400).json({
      message: e.message,
    });
  }
}

export async function login(req, res) {
  try {
    const { email, password } = req.body;

    const normalizedEmail = String(email || "")
      .trim()
      .toLowerCase();

    const { rows } = await query(
      `
      SELECT
        u.id,
        u.name,
        u.email,
        u.password_hash,
        r.name AS role,

        EXISTS (
          SELECT 1
          FROM subscriptions s
          WHERE
            s.user_id = u.id
            AND s.status = 'active'
            AND s.start_date <= NOW()
            AND s.end_date > NOW()
        ) AS has_active_subscription

      FROM users u
      JOIN roles r
        ON r.id = u.role_id

      WHERE u.email = $1
      `,
      [normalizedEmail]
    );

    if (
      !rows[0] ||
      !(await comparePassword(
        password || "",
        rows[0].password_hash
      ))
    ) {
      return res.status(401).json({
        message: "Invalid email or password",
      });
    }

    const {
      password_hash,
      ...user
    } = rows[0];

    return res.json({
      token: signToken(user),
      user,
    });
  } catch (e) {
    console.error("Login error:", e);

    return res.status(500).json({
      message: "Login failed",
    });
  }
}

export async function me(req, res) {
  return res.json({
    user: req.user,
  });
}