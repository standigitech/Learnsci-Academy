import helmet from "helmet";
import cors from "cors";
import rateLimit from "express-rate-limit";
import { env } from "../config/env.js";
export const security = [
  helmet(),
  cors({origin:env.frontend,credentials:false}),
  rateLimit({windowMs:15*60*1000,max:300,standardHeaders:true,legacyHeaders:false})
];
