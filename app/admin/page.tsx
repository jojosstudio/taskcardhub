"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { ArrowLeft, BarChart3, ExternalLink, FileText, ShieldCheck } from "lucide-react";
import { UserButton } from "@clerk/nextjs";

type Analytics = {
  totals: { taskcards: number; openReports: number; activeUsers: number; pageViews: number; linkOpens: number };
  taskcardUsage: { id: string; title: string; subject: string; views: number; opens: number }[];
  unconfirmed: { id: string; title: string; subject: string; grade: string; course: string; url: string; teachers: { name: string }[] }[];
};

export default function AdminPage() {
  const [data, setData] = useState<Analytics | null>(null);
  const [error, setError] = useState("");
  const [unconfirmed, setUnconfirmed] = useState<Analytics["unconfirmed"]>([]);
  useEffect(() => {
    void fetch("/api/analytics").then(async (response) => {
      if (!response.ok) throw new Error("Adminrechte erforderlich.");
      const result = await response.json() as Analytics;
      setData(result);
      setUnconfirmed(result.unconfirmed);
    }).catch((reason: Error) => setError(reason.message));
  }, []);

  async function confirmCard(id: string) {
    const response = await fetch(`/api/taskcards/${id}`, { method: "PATCH", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ confirmed: true }) });
    if (response.ok) setUnconfirmed((items) => items.filter((item) => item.id !== id));
  }

  return <main><nav className="topbar"><div className="brand"><div className="brand-mark">T</div><span>taskcard<span className="muted">.hub</span></span><span className="admin-badge">ADMIN</span></div><div className="nav-actions"><Link href="/" className="back-link">← Sammlung</Link><UserButton /></div></nav><section className="admin-hero"><p className="eyebrow">ÜBERSICHT & VERWALTUNG</p><h1>Analytics Dashboard</h1><p>Behalte Nutzung, Aktivität und Meldungen deiner Taskcard-Sammlung im Blick.</p></section><section className="content admin-content">{error && <div className="error-banner">{error}</div>}{data && <><div className="analytics-grid"><div><BarChart3 /><strong>{data.totals.pageViews}</strong><span>Seitenaufrufe · 30 Tage</span></div><div><ShieldCheck /><strong>{data.totals.activeUsers}</strong><span>Aktive Nutzer · 30 Tage</span></div><div><ExternalLink /><strong>{data.totals.linkOpens}</strong><span>Link-Öffnungen · 30 Tage</span></div><div><FileText /><strong>{data.totals.openReports}</strong><span>Offene Meldungen</span></div></div><section className="analytics-panel"><div className="panel-heading"><div><p className="eyebrow">NUTZUNG</p><h2>Meistgenutzte Taskcards</h2></div><span>{data.totals.taskcards} insgesamt</span></div>{data.taskcardUsage.length ? data.taskcardUsage.map((card, index) => <div className="usage-row" key={card.id}><span className="usage-rank">{index + 1}</span><div className="usage-name"><strong>{card.title}</strong><small>{card.subject}</small></div><div className="usage-bar"><i style={{ width: `${Math.min(100, ((card.views + card.opens) / Math.max(1, data.taskcardUsage[0].views + data.taskcardUsage[0].opens)) * 100)}%` }} /></div><span className="usage-count">{card.views + card.opens} Events</span>  </div>) : <p className="empty-small">Noch keine Nutzungsdaten vorhanden.</p>}</section><section className="analytics-panel review-panel"><div className="panel-heading"><div><p className="eyebrow">PRÜFUNG</p><h2>Noch nicht bestätigt</h2></div><span>{unconfirmed.length} offen</span></div>{unconfirmed.length ? unconfirmed.map((card) => <div className="review-row" key={card.id}><div><strong>{card.title}</strong><p>{card.grade} · {card.course} · {card.subject}</p><small>{card.teachers.map((teacher) => teacher.name).join(", ")}</small></div><div className="review-actions"><a href={card.url} target="_blank" rel="noreferrer">Link prüfen <ExternalLink size={14} /></a><button className="confirm-button" onClick={() => confirmCard(card.id)}>Bestätigen</button></div></div>) : <p className="empty-small">Alle Taskcards sind bestätigt.</p>}</section><section className="admin-links"><h2>Verwaltung & Rechtliches</h2><Link href="/#reports">Meldungen bearbeiten <ArrowLeft size={15} /></Link><Link href="/datenschutz">Datenschutz <ArrowLeft size={15} /></Link><Link href="/nutzungsbedingungen">Nutzungsbedingungen <ArrowLeft size={15} /></Link></section></>}</section></main>;
}
