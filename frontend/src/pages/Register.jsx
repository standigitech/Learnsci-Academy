import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { authApi } from "../services/api";
import { useAuth } from "../hooks/useAuth";
import AuthLayout from "../layouts/AuthLayout";
export default function Register() {
  const [form,setForm]=useState({name:"",email:"",password:"",confirmPassword:""});
  const [error,setError]=useState("");
  const {login}=useAuth(); const navigate=useNavigate();
  async function submit(e){e.preventDefault();setError("");try{if(form.password!==form.confirmPassword)throw new Error("Passwords do not match");const {data}=await authApi.register(form);login(data.token,data.user);navigate("/subscribe");}catch(err){setError(err.response?.data?.message||err.message||"Registration failed");}}
  return <AuthLayout><h2>Create your LearnSci account</h2><p className="muted">Registration is followed immediately by subscription selection.</p><form onSubmit={submit} className="form"><label>Full name<input required value={form.name} onChange={e=>setForm({...form,name:e.target.value})}/></label><label>Email<input type="email" required value={form.email} onChange={e=>setForm({...form,email:e.target.value})}/></label><label>Password<input type="password" minLength="8" required value={form.password} onChange={e=>setForm({...form,password:e.target.value})}/></label><label>Confirm password<input type="password" required value={form.confirmPassword} onChange={e=>setForm({...form,confirmPassword:e.target.value})}/></label>{error&&<div className="error">{error}</div>}<button className="btn primary full">Create account</button></form><p className="auth-switch">Already registered? <Link to="/login">Login</Link></p></AuthLayout>
}
