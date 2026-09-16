import dotenv from "dotenv";

dotenv.config();

export const env = {
port: Number(process.env.PORT || 4000),

DATABASE_URL: process.env.DATABASE_URL,

jwtSecret: process.env.JWT_SECRET || "dev-only-secret-change-me",

frontend: process.env.FRONTEND_URL || "http://localhost:5173",

nodeEnv: process.env.NODE_ENV || "development",

stripeSecret: process.env.STRIPE_SECRET_KEY,
stripeWebhookSecret: process.env.STRIPE_WEBHOOK_SECRET,
stripeSuccessUrl: process.env.STRIPE_SUCCESS_URL,
stripeCancelUrl: process.env.STRIPE_CANCEL_URL,

mpesaConsumerKey: process.env.MPESA_CONSUMER_KEY,
mpesaConsumerSecret: process.env.MPESA_CONSUMER_SECRET,
mpesaShortcode: process.env.MPESA_SHORTCODE,
mpesaPasskey: process.env.MPESA_PASSKEY,
mpesaCallbackUrl: process.env.MPESA_CALLBACK_URL,
mpesaEnv: process.env.MPESA_ENV || "sandbox"
};

