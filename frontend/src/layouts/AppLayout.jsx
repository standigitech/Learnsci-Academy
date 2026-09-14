import { useState } from "react";
import { NavLink, Outlet } from "react-router-dom";
import { BookOpen, LayoutDashboard, GraduationCap, Video, ClipboardCheck, FileText, BarChart3, Award, Menu, X, LogOut, Settings, Search } from "lucide-react";
import Logo from "../components/Logo";
import { useAuth } from "../hooks/useAuth";

const links = [
  ["/dashboard","Dashboard",LayoutDashboard],
  ["/subjects","Subjects",BookOpen],
  ["/courses","My Courses",GraduationCap],
  ["/classes","Live Classes",Video],
  ["/exams","Quizzes & Exams",ClipboardCheck],
  ["/resources","Resources",FileText],
  ["/articles","Articles",FileText],
  ["/progress","Progress",BarChart3],
  ["/certificates","Certificates",Award]
];

export default function AppLayout() {
  const [open, setOpen] = useState(false);
  const { user, logout } = useAuth();
  const nav = [...links];
  if (user?.role === "teacher") nav.push(["/teacher","Teacher Dashboard",LayoutDashboard]);
  if (user?.role === "admin") nav.push(["/admin","Admin Dashboard",LayoutDashboard]);

  return <div className="app-shell">
    <aside className={`sidebar ${open ? "open" : ""}`}>
      <div className="side-top"><Logo/><button className="icon-btn mobile-only" onClick={()=>setOpen(false)} aria-label="Close menu"><X/></button></div>
      <nav>{nav.map(([to,label,Icon])=><NavLink key={to} to={to} onClick={()=>setOpen(false)} className={({isActive})=>isActive?"active":""}><Icon size={18}/><span>{label}</span></NavLink>)}</nav>
      <div className="side-bottom">
        <NavLink to="/settings"><Settings size={18}/>Settings</NavLink>
        <button onClick={logout}><LogOut size={18}/>Logout</button>
      </div>
    </aside>
    {open && <button className="overlay" onClick={()=>setOpen(false)} aria-label="Close navigation"></button>}
    <div className="main">
      <header className="topbar">
        <button className="icon-btn mobile-only" onClick={()=>setOpen(true)} aria-label="Open menu"><Menu/></button>
        <div className="global-search"><Search size={18}/><input placeholder="Search lessons, topics or resources" aria-label="Search"/></div>
        <div className="profile"><div className="avatar">{user?.name?.[0]?.toUpperCase()}</div><div><strong>{user?.name}</strong><small>{user?.role}</small></div></div>
      </header>
      <Outlet/>
    </div>
  </div>;
}
