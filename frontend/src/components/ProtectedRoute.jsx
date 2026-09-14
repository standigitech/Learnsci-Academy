import { Navigate, Outlet, useLocation } from "react-router-dom";
import { useAuth } from "../hooks/useAuth";

export default function ProtectedRoute({ premium = false, roles = [] }) {
  const { user, loading } = useAuth();
  const location = useLocation();
  if (loading) return <div className="screen-center">Loading LearnSci…</div>;
  if (!user) return <Navigate to="/login" state={{ from: location.pathname }} replace />;
  if (roles.length && !roles.includes(user.role)) return <Navigate to="/dashboard" replace />;
  if (premium && !user.hasActiveSubscription) return <Navigate to="/subscribe" state={{ from: location.pathname }} replace />;
  return <Outlet />;
}
