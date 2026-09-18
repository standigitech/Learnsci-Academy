import { verifyToken } from "../utils/auth.js";
import { query } from "../db.js";

export async function requireAuth(req, res, next) {
  try {
    const header = req.headers.authorization || "";

    if (!header.startsWith("Bearer ")) {
      return res.status(401).json({
        message: "Authentication required",
      });
    }

    const token = header.slice(7);
    const payload = verifyToken(token);

    const { rows } = await query(
      `
      SELECT
        u.id,
        u.name,
        u.email,
        r.name AS role,
        EXISTS (
          SELECT 1
          FROM subscriptions s
          WHERE s.user_id = u.id
            AND s.status = 'active'
            AND s.start_date <= NOW()
            AND s.end_date > NOW()
        ) AS has_active_subscription
      FROM users u
      JOIN roles r ON r.id = u.role_id
      WHERE u.id = $1
      `,
      [payload.sub]
    );

    if (!rows[0]) {
      return res.status(401).json({
        message: "User not found",
      });
    }

    req.user = rows[0];
    next();
  } catch (error) {
    console.error("Authentication error:", error);

    return res.status(401).json({
      message: "Invalid or expired token",
    });
  }
}

export function requireRole(...roles) {
  return (req, res, next) => {
    if (roles.includes(req.user?.role)) {
      return next();
    }

    return res.status(403).json({
      message: "Insufficient permissions",
    });
  };
}

export function requireSubscription(req, res, next) {
  if (req.user?.has_active_subscription) {
    return next();
  }

  return res.status(402).json({
    message: "An active LearnSci subscription is required",
  });
}