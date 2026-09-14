import { LockKeyhole } from "lucide-react";
import { Link } from "react-router-dom";
export default function Paywall({ title="Premium learning is locked", text="Activate a LearnSci subscription to unlock this lesson, quiz and resources." }) {
  return <div className="paywall"><LockKeyhole size={30}/><h2>{title}</h2><p>{text}</p><Link className="btn primary" to="/subscribe">Choose a subscription</Link></div>;
}
