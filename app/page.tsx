"use client";

import { useEffect, useMemo, useState } from "react";
import { Plus, Search, ExternalLink, CheckCircle2, Clock3, Trash2, X, BookOpen, Users, ShieldCheck, LayoutDashboard, Sparkles } from "lucide-react";
import { SignInButton, UserButton, useAuth } from "@clerk/nextjs";
import Link from "next/link";

type Card = {
  id: string;
  title: string;
  subject: string;
  grade: string;
  course: string;
  topic: string;
  url: string;
  description?: string | null;
  confirmed: boolean;
  createdByName: string;
  teachers: { id: string; name: string }[];
};
type Report = {
  id: string;
  reason: string;
  message: string;
  status: string;
  adminNote?: string | null;
  taskcard: { title: string; url: string };
};

const emptyForm = { title: "", subject: "", grade: "", course: "", topic: "", teachers: "", url: "", description: "" };

export default function Home() {
  const { isSignedIn } = useAuth();
  const [cards, setCards] = useState<Card[]>([]);
  const [reports, setReports] = useState<Report[]>([]);
  const [canManage, setCanManage] = useState(false);
  const [query, setQuery] = useState("");
  const [subject, setSubject] = useState("Alle Fächer");
  const [grade, setGrade] = useState("Alle Stufen");
  const [status, setStatus] = useState("Alle Status");
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState(emptyForm);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [warningCard, setWarningCard] = useState<Card | null>(null);
  const [deleteCardId, setDeleteCardId] = useState<string | null>(null);
  const [reportingCard, setReportingCard] = useState<Card | null>(null);
  const [reportReason, setReportReason] = useState("Link funktioniert nicht");
  const [reportMessage, setReportMessage] = useState("");
  const [reportSending, setReportSending] = useState(false);
  const [showEasterEgg, setShowEasterEgg] = useState(false);

  async function loadCards() {
    try {
      const response = await fetch("/api/taskcards");
      if (!response.ok) {
        setError(response.status === 401 || response.status === 404
          ? "Deine Anmeldung ist nicht aktiv. Bitte melde dich erneut an."
          : "Die Taskcards konnten nicht geladen werden.");
        return;
      }
      const data = await response.json() as { cards: Card[]; canManage: boolean };
      setCards(data.cards);
      setCanManage(data.canManage);
      if (data.canManage) {
        const reportsResponse = await fetch("/api/reports");
        if (reportsResponse.ok) setReports(await reportsResponse.json());
      }
      setError("");
    } catch {
      setError("Der Server ist momentan nicht erreichbar.");
    }
  }
  useEffect(() => { void loadCards(); }, []);
  useEffect(() => { void fetch("/api/analytics", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ type: "page_view" }) }); }, []);
  useEffect(() => {
    let typed = "";
    const handleKeyDown = (event: KeyboardEvent) => {
      typed = `${typed}${event.key.toLowerCase()}`.slice(-8);
      if (typed === "taskcard") {
        setShowEasterEgg(true);
        typed = "";
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, []);

  const subjects = useMemo(() => ["Alle Fächer", ...Array.from(new Set(cards.map((card) => card.subject).filter(Boolean)))], [cards]);
  const grades = useMemo(() => ["Alle Stufen", ...Array.from(new Set(cards.map((card) => card.grade).filter(Boolean)))], [cards]);
  const filtered = cards.filter((card) => {
    const haystack = `${card.title} ${card.subject} ${card.grade} ${card.course} ${card.topic} ${card.teachers.map((teacher) => teacher.name).join(" ")}`.toLowerCase();
    return haystack.includes(query.toLowerCase()) && (subject === "Alle Fächer" || card.subject === subject) && (grade === "Alle Stufen" || card.grade === grade) &&
      (status === "Alle Status" || (status === "Bestätigt" ? card.confirmed : !card.confirmed));
  });

  async function addCard(event: React.FormEvent) {
    event.preventDefault(); setSaving(true); setError("");
    const response = await fetch("/api/taskcards", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(form) });
    if (!response.ok) { setError("Taskcard konnte nicht gespeichert werden."); setSaving(false); return; }
    setForm(emptyForm); setShowForm(false); setSaving(false); await loadCards();
  }

  async function confirmCard(id: string, confirmed: boolean) {
    await fetch(`/api/taskcards/${id}`, { method: "PATCH", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ confirmed }) });
    await loadCards();
  }

  function removeCard(id: string) {
    setDeleteCardId(id);
  }

  async function confirmDelete() {
    if (!deleteCardId) return;
    const id = deleteCardId;
    setDeleteCardId(null);
    await fetch(`/api/taskcards/${id}`, { method: "DELETE" }); await loadCards();
  }

  function reportCard(card: Card) {
    if (!isSignedIn) {
      window.location.assign("/sign-in");
      return;
    }
    setReportReason("Link funktioniert nicht");
    setReportMessage("");
    setReportingCard(card);
  }

  async function submitReport(event: React.FormEvent) {
    event.preventDefault();
    if (!reportingCard || !reportMessage.trim()) return;
    setReportSending(true);
    const response = await fetch("/api/reports", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ taskcardId: reportingCard.id, reason: reportReason, message: reportMessage }) });
    setReportSending(false);
    if (response.ok) {
      setReportingCard(null);
      setError("Danke, deine Meldung wurde an die Admins gesendet.");
    } else {
      setError("Die Meldung konnte nicht gesendet werden.");
    }
  }

  async function updateReport(report: Report, status: string, adminNote: string) {
    const response = await fetch(`/api/reports/${report.id}`, { method: "PATCH", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ status, adminNote }) });
    if (response.ok) setReports((items) => items.map((item) => item.id === report.id ? { ...item, status, adminNote } : item));
  }

  return (
    <main>
      <nav className="topbar"><div className="brand"><button className="brand-mark secret-mark" aria-label="Taskcard Hub Logo" onClick={() => setShowEasterEgg(true)}>T</button><span>taskcard<span className="muted">.hub</span></span></div><div className="nav-actions">{canManage && <Link href="/admin" className="admin-nav"><LayoutDashboard size={15} /> Admin</Link>}{isSignedIn ? <UserButton /> : <SignInButton mode="modal"><button className="login-button">Anmelden</button></SignInButton>}</div></nav>
      <section className="hero"><div><p className="eyebrow">EURE ZENTRALE SAMMLUNG</p><h1>Alle Taskcards<br /><em>an einem Ort.</em></h1><p className="hero-copy">Sammelt, sortiert und teilt eure Taskcards übersichtlich.</p></div>{isSignedIn ? <button className="primary-button" onClick={() => setShowForm(true)}><Plus size={18} /> Taskcard hinzufügen</button> : <SignInButton mode="modal"><button className="primary-button"><Plus size={18} /> Anmelden zum Hinzufügen</button></SignInButton>}</section>
      <section className="content">
        <div className="stats"><div><BookOpen size={19} /><strong>{cards.length}</strong><span>Taskcards gesamt</span></div><div><CheckCircle2 size={19} /><strong>{cards.filter((card) => card.confirmed).length}</strong><span>Bestätigt</span></div><div><Users size={19} /><strong>{new Set(cards.flatMap((card) => card.teachers.map((teacher) => teacher.name))).size}</strong><span>Lehrkräfte</span></div></div>
        <div className="toolbar"><div className="search"><Search size={18} /><input placeholder="Suche nach Thema, Kurs, Lehrkraft ..." value={query} onChange={(event) => setQuery(event.target.value)} /></div><select value={grade} onChange={(event) => setGrade(event.target.value)}>{grades.map((item) => <option key={item}>{item}</option>)}</select><select value={subject} onChange={(event) => setSubject(event.target.value)}>{subjects.map((item) => <option key={item}>{item}</option>)}</select><select value={status} onChange={(event) => setStatus(event.target.value)}><option>Alle Status</option><option>Bestätigt</option><option>Nicht bestätigt</option></select></div>
        {error && <div className="error-banner">{error}</div>}<div className="result-line"><span><strong>{filtered.length}</strong> Ergebnisse</span><span className="hint"><ShieldCheck size={15} /> Bestätigte Links sind geprüft</span></div>
        <div className="card-grid">{filtered.map((card) => <article className="task-card" key={card.id}><div className="card-top"><span className="subject-tag">{card.subject}</span><span className={card.confirmed ? "status confirmed" : "status pending"}>{card.confirmed ? <CheckCircle2 size={14} /> : <Clock3 size={14} />}{card.confirmed ? "Bestätigt" : "Nicht bestätigt"}</span></div><h2>{card.title}</h2><p className="meta">{card.grade} <span>·</span> {card.course} <span>·</span> {card.topic}</p>{card.description && <p className="description">{card.description}</p>}<div className="card-byline">Hinzugefügt von <strong>{card.createdByName}</strong></div><div className="teachers">{card.teachers.map((teacher) => <span key={teacher.id}>{teacher.name}</span>)}</div><div className="card-footer"><div className="card-links"><a className="open-link" href={card.url} target="_blank" rel="noreferrer" onClick={(event) => { if (!card.confirmed) { event.preventDefault(); setWarningCard(card); return; } void fetch("/api/analytics", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ type: "taskcard_open", taskcardId: card.id }) }); }}>Taskcard öffnen <ExternalLink size={15} /></a><button className="report-link" onClick={() => reportCard(card)}>Melden</button></div>{canManage && <div className="admin-actions">{!card.confirmed && <button className="confirm-button" onClick={() => confirmCard(card.id, true)}>Bestätigen</button>}<button className="icon-button" title="Löschen" onClick={() => removeCard(card.id)}><Trash2 size={15} /></button></div>}</div></article>)}</div>
        {!filtered.length && <div className="empty"><Search size={30} /><h3>Keine Taskcards gefunden</h3><p>Versuche einen anderen Suchbegriff oder füge eine neue Taskcard hinzu.</p></div>}
        {canManage && <section id="reports" className="reports-panel"><div className="panel-heading"><div><p className="eyebrow">ADMIN-BEREICH</p><h2>Meldungen bearbeiten</h2></div><span>{reports.filter((report) => report.status === "open").length} offen</span></div>{reports.length ? reports.map((report) => <div className="report-row" key={report.id}><div><strong>{report.taskcard.title}</strong><p><b>{report.reason}</b> · {report.message}</p><a href={report.taskcard.url} target="_blank" rel="noreferrer">Link prüfen</a></div><div className="report-controls"><select value={report.status} onChange={(event) => updateReport(report, event.target.value, report.adminNote ?? "")}><option value="open">Offen</option><option value="in_review">In Prüfung</option><option value="resolved">Erledigt</option><option value="dismissed">Verworfen</option></select><input defaultValue={report.adminNote ?? ""} placeholder="Admin-Notiz" onBlur={(event) => updateReport(report, report.status, event.target.value)} /></div></div>) : <p className="empty-small">Noch keine Meldungen vorhanden.</p>}</section>}
      </section>
      {showForm && <div className="modal-backdrop" onMouseDown={(event) => { if (event.target === event.currentTarget) setShowForm(false); }}><form className="modal" onSubmit={addCard}><div className="modal-header"><div><p className="eyebrow">NEUE SAMMLUNG</p><h2>Taskcard hinzufügen</h2></div><button type="button" className="close" onClick={() => setShowForm(false)}><X /></button></div><div className="form-grid"><label>Titel<input required value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} placeholder="z. B. Einführung in ..."/></label><label>Fach<input required value={form.subject} onChange={(e) => setForm({ ...form, subject: e.target.value })} placeholder="z. B. Englisch"/></label><label>Stufe / Klasse<input required value={form.grade} onChange={(e) => setForm({ ...form, grade: e.target.value })} placeholder="z. B. EF, 8a, Q1"/></label><label>Kurs<input required value={form.course} onChange={(e) => setForm({ ...form, course: e.target.value })} placeholder="z. B. ER GK1"/></label><label>Thema<input required value={form.topic} onChange={(e) => setForm({ ...form, topic: e.target.value })} placeholder="z. B. Medienkompetenz"/></label><label className="wide">Lehrkräfte <span className="label-hint">(mehrere mit Komma trennen)</span><input required value={form.teachers} onChange={(e) => setForm({ ...form, teachers: e.target.value })} placeholder="z. B. Frau Müller, Herr Schmidt"/></label><label className="wide">Taskcard-Link<input required type="url" value={form.url} onChange={(e) => setForm({ ...form, url: e.target.value })} placeholder="https://..."/></label><label className="wide">Kurzbeschreibung <span className="label-hint">(optional)</span><textarea value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} placeholder="Worum geht es in dieser Taskcard?"/></label></div>{error && <p className="error">{error}</p>}<div className="modal-footer"><button type="button" className="secondary-button" onClick={() => setShowForm(false)}>Abbrechen</button><button className="primary-button" disabled={saving}>{saving ? "Wird gespeichert ..." : "Taskcard speichern"}</button></div></form></div>}
      <footer className="site-footer"><span>Made by Lenodro &amp; Jojosstudio</span><span><a href="/datenschutz">Datenschutz</a><a href="/nutzungsbedingungen">Nutzungsbedingungen</a></span></footer>
      {warningCard && <div className="modal-backdrop" onMouseDown={(event) => { if (event.target === event.currentTarget) setWarningCard(null); }}><div className="warning-modal"><div className="warning-icon"><ShieldCheck size={25} /></div><p className="eyebrow">SICHERHEITSHINWEIS</p><h2>Dieser Link wurde noch nicht bestätigt</h2><p>Diese Taskcard wurde noch nicht von einem Lehrer oder Admin geprüft. Der Link kann fehlerhaft oder unsicher sein.</p><div className="warning-actions"><button className="secondary-button" onClick={() => setWarningCard(null)}>Abbrechen</button><a className="primary-button" href={warningCard.url} target="_blank" rel="noreferrer" onClick={() => { void fetch("/api/analytics", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ type: "taskcard_open", taskcardId: warningCard.id }) }); setWarningCard(null); }}>Trotzdem öffnen <ExternalLink size={15} /></a></div></div></div>}
      {deleteCardId && <div className="modal-backdrop" onMouseDown={(event) => { if (event.target === event.currentTarget) setDeleteCardId(null); }}><div className="warning-modal"><div className="warning-icon danger"><Trash2 size={22} /></div><p className="eyebrow">ADMIN-AKTION</p><h2>Taskcard löschen?</h2><p>„{cards.find((card) => card.id === deleteCardId)?.title}“ wird dauerhaft aus der Sammlung entfernt.</p><div className="warning-actions"><button className="secondary-button" onClick={() => setDeleteCardId(null)}>Abbrechen</button><button className="danger-button" onClick={confirmDelete}>Endgültig löschen</button></div></div></div>}
      {reportingCard && <div className="modal-backdrop" onMouseDown={(event) => { if (event.target === event.currentTarget) setReportingCard(null); }}><form className="warning-modal report-modal" onSubmit={submitReport}><div className="warning-icon"><ShieldCheck size={22} /></div><p className="eyebrow">RÜCKMELDUNG</p><h2>Taskcard melden</h2><p>Was ist bei „{reportingCard.title}“ auffällig?</p><label>Grund<select value={reportReason} onChange={(event) => setReportReason(event.target.value)}><option>Link funktioniert nicht</option><option>Link ist unsicher</option><option>Inhalt ist falsch</option><option>Unpassender Inhalt</option><option>Sonstiges</option></select></label><label>Beschreibung<textarea required value={reportMessage} onChange={(event) => setReportMessage(event.target.value)} placeholder="Beschreibe kurz das Problem ..." /></label><div className="warning-actions"><button type="button" className="secondary-button" onClick={() => setReportingCard(null)}>Abbrechen</button><button className="primary-button" disabled={reportSending}>{reportSending ? "Wird gesendet ..." : "Meldung senden"}</button></div></form></div>}
      {showEasterEgg && <div className="modal-backdrop" onMouseDown={(event) => { if (event.target === event.currentTarget) setShowEasterEgg(false); }}><div className="easter-modal"><div className="easter-stars"><Sparkles size={28} /><Sparkles size={16} /><Sparkles size={20} /></div><p className="eyebrow">GEHEIME SAMMLUNG</p><h2>Du hast den geheimen Bereich gefunden.</h2><p>Zwischen all den Taskcards versteckt sich immer noch ein kleines bisschen Magie. Danke, dass du Taskcard Hub ausprobierst.</p><strong>Made by Lenodro &amp; Jojosstudio</strong><button className="primary-button" onClick={() => setShowEasterEgg(false)}>Zurück zur Sammlung</button></div></div>}
    </main>
  );
}
