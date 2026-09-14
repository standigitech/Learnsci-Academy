import { Routes,Route } from "react-router-dom";
import { AuthProvider } from "./hooks/useAuth";
import ProtectedRoute from "./components/ProtectedRoute";
import AppLayout from "./layouts/AppLayout";
import Landing from "./pages/Landing";
import Register from "./pages/Register";
import Login from "./pages/Login";
import Subscribe from "./pages/Subscribe";
import PaymentStatus from "./pages/PaymentStatus";
import Dashboard from "./pages/Dashboard";
import Subjects from "./pages/Subjects";
import Subject from "./pages/Subject";
import Lesson from "./pages/Lesson";
import Quiz from "./pages/Quiz";
import Articles from "./pages/Articles";
import Teacher from "./pages/Teacher";
import Admin from "./pages/Admin";
import Placeholder from "./pages/Placeholder";

export default function App(){return <AuthProvider><Routes>
  <Route path="/" element={<Landing/>}/><Route path="/register" element={<Register/>}/><Route path="/login" element={<Login/>}/>
  <Route path="/subscribe" element={<ProtectedRoute><Subscribe/></ProtectedRoute>}/><Route path="/payment/success" element={<ProtectedRoute><PaymentStatus success/></ProtectedRoute>}/><Route path="/payment/failed" element={<ProtectedRoute><PaymentStatus success={false}/></ProtectedRoute>}/>
  <Route element={<ProtectedRoute roles={["learner","teacher","admin"]}/>}><Route element={<AppLayout/>}>
    <Route path="/dashboard" element={<Dashboard/>}/><Route path="/subjects" element={<Subjects/>}/><Route path="/subjects/:slug" element={<Subject/>}/>
    <Route path="/lessons/:id" element={<ProtectedRoute premium><Lesson/></ProtectedRoute>}/><Route path="/quizzes/:id" element={<ProtectedRoute premium><Quiz/></ProtectedRoute>}/>
    <Route path="/courses" element={<ProtectedRoute premium><Placeholder title="My Courses"/></ProtectedRoute>}/><Route path="/classes" element={<ProtectedRoute premium><Placeholder title="Live Classes"/></ProtectedRoute>}/><Route path="/exams" element={<ProtectedRoute premium><Placeholder title="Quizzes & Exams"/></ProtectedRoute>}/><Route path="/resources" element={<ProtectedRoute premium><Placeholder title="Resources"/></ProtectedRoute>}/><Route path="/progress" element={<ProtectedRoute premium><Placeholder title="Learning Progress"/></ProtectedRoute>}/><Route path="/certificates" element={<ProtectedRoute premium><Placeholder title="Certificates"/></ProtectedRoute>}/><Route path="/settings" element={<Placeholder title="Settings"/>}/><Route path="/articles" element={<Articles/>}/>
    <Route path="/teacher" element={<ProtectedRoute roles={["teacher","admin"]}><Teacher/></ProtectedRoute>}/><Route path="/admin" element={<ProtectedRoute roles={["admin"]}><Admin/></ProtectedRoute>}/>
  </Route></Route>
</Routes></AuthProvider>}
