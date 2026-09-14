import { Router } from "express";
import { subjects,subject,lesson,articles,quiz } from "../controllers/contentController.js";
import { requireAuth,requireSubscription } from "../middleware/auth.js";
const r=Router();r.get("/subjects",requireAuth,subjects);r.get("/subjects/:slug",requireAuth,subject);r.get("/lessons/:id",requireAuth,lesson);r.get("/articles",requireAuth,articles);r.get("/quizzes/:id",requireAuth,requireSubscription,quiz);export default r;
