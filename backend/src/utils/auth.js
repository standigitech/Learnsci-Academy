import jwt from "jsonwebtoken";
import bcrypt from "bcryptjs";
import { env } from "../config/env.js";
export const hashPassword = (p) => bcrypt.hash(p, 12);
export const comparePassword = (p,h) => bcrypt.compare(p,h);
export function signToken(user){return jwt.sign({sub:user.id,role:user.role},env.jwtSecret,{expiresIn:"7d"});}
export function verifyToken(token){return jwt.verify(token,env.jwtSecret);}
