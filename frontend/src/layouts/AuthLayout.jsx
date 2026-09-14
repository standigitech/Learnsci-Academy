import Logo from "../components/Logo";
export default function AuthLayout({ children }) {
  return <main className="auth-shell"><div className="auth-brand"><Logo/><h1>Your science journey starts here.</h1><p>Build knowledge, master key concepts and achieve your goals with LearnSci.</p></div><section className="auth-card">{children}</section></main>;
}
