import { Link } from "react-router-dom";
import { api } from "../services/api";
import { useEffect,useState } from "react";
export default function Subjects(){const [subjects,setSubjects]=useState([]);useEffect(()=>{api.get("/subjects").then(r=>setSubjects(r.data.subjects));},[]);return <main className="page"><div className="page-title"><h1>Explore Subjects</h1><p>Choose a subject and build your understanding topic by topic.</p></div><div className="subject-grid">{subjects.map(s=><Link to={`/subjects/${s.slug}`} className={`subject-card ${s.color}`} key={s.id}><span className="subject-letter">{s.name[0]}</span><h2>{s.name}</h2><p>{s.topicCount} topics · {s.lessonCount} lessons</p><span>Explore subject →</span></Link>)}</div></main>}
