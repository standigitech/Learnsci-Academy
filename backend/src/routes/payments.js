import { Router } from "express";
import { checkout,simulateSuccess,history,subscription,mpesaCallback,stripeWebhook } from "../controllers/paymentController.js";
import { requireAuth } from "../middleware/auth.js";
const r=Router();r.post("/checkout",requireAuth,checkout);r.post("/simulate-success",requireAuth,simulateSuccess);r.get("/history",requireAuth,history);r.get("/subscriptions/me",requireAuth,subscription);r.post("/mpesa/callback",mpesaCallback);export default r;
