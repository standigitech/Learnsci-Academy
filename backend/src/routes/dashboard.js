import { Router } from "express";
import { requireAuth,requireRole,requireSubscription } from "../middleware/auth.js";
import { dashboard,teacherDashboard,adminDashboard,attemptQuiz } from "../controllers/dashboardController.js";
const r=Router();r.get("/dashboard",requireAuth,dashboard);r.get("/teacher/dashboard",requireAuth,requireRole("teacher","admin"),teacherDashboard);r.get("/admin/dashboard",requireAuth,requireRole("admin"),adminDashboard);r.post("/quizzes/:id/attempts",requireAuth,requireSubscription,attemptQuiz);export default r;
