import { CalendarRange, Plus, RefreshCw, Search, Sparkles } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { deleteEvent, fetchEvents, saveEvent } from "./api";
import { EventCard } from "./EventCard";
import { EventForm } from "./EventForm";
import type { EventFormValues, EventItem } from "./types";

export default function App(): JSX.Element {
  const [events, setEvents] = useState<EventItem[]>([]);
  const [query, setQuery] = useState("");
  const [debouncedQuery, setDebouncedQuery] = useState("");
  const [editing, setEditing] = useState<EventItem | null | undefined>(undefined);
  const [deleting, setDeleting] = useState<EventItem | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [formError, setFormError] = useState<string | null>(null);

  useEffect(() => {
    const timeout = window.setTimeout(() => setDebouncedQuery(query), 280);
    return () => window.clearTimeout(timeout);
  }, [query]);

  useEffect(() => { void loadEvents(debouncedQuery); }, [debouncedQuery]);

  async function loadEvents(search: string): Promise<void> {
    setLoading(true);
    setError(null);
    try { setEvents(await fetchEvents(search)); }
    catch (loadError) { setError(loadError instanceof Error ? loadError.message : "No pudimos cargar los eventos."); }
    finally { setLoading(false); }
  }

  async function save(values: EventFormValues, cover: File | null, removeCover: boolean): Promise<void> {
    setSaving(true);
    setFormError(null);
    try {
      await saveEvent(editing?.id ?? null, values, cover, removeCover);
      setEditing(undefined);
      await loadEvents(debouncedQuery);
    } catch (saveError) {
      setFormError(saveError instanceof Error ? saveError.message : "No pudimos guardar el evento.");
    } finally { setSaving(false); }
  }

  async function confirmDelete(): Promise<void> {
    if (!deleting) return;
    try { await deleteEvent(deleting.id); setDeleting(null); await loadEvents(debouncedQuery); }
    catch (deleteError) { setError(deleteError instanceof Error ? deleteError.message : "No pudimos eliminar el evento."); setDeleting(null); }
  }

  const upcomingCount = useMemo(() => events.filter((event) => new Date(event.starts_at).getTime() >= Date.now()).length, [events]);

  return (
    <div className="app-shell">
      <header className="topbar"><a className="brand" href="#top" aria-label="Eventos Cero"><span><CalendarRange /></span><strong>EVENTOS<small>CERO</small></strong></a><div className="lab-badge"><span /> Laboratorio público</div></header>
      <main id="top">
        <section className="hero">
          <div className="hero-copy"><p className="eyebrow light"><Sparkles size={14} /> Hecho para compartir</p><h1>Momentos que merecen <em>un buen anuncio.</em></h1><p>Crea una cartelera pequeña, clara y lista para verse desde cualquier pantalla.</p><button className="button hero-button" onClick={() => { setFormError(null); setEditing(null); }}><Plus /> Publicar evento</button></div>
          <div className="hero-metric"><span>Próximos</span><strong>{upcomingCount.toString().padStart(2, "0")}</strong><small>eventos en cartelera</small></div>
        </section>

        <section className="catalog-panel">
          <div className="catalog-header"><div><p className="eyebrow">Cartelera pública</p><h2>Explora los eventos</h2><p>{events.length} {events.length === 1 ? "publicación" : "publicaciones"} visibles</p></div><div className="catalog-tools"><label className="search"><Search /><input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Buscar por título o ubicación" /><kbd>/</kbd></label><button className="icon-button" onClick={() => void loadEvents(debouncedQuery)} aria-label="Actualizar"><RefreshCw className={loading ? "spin" : ""} /></button></div></div>
          {error ? <p className="feedback error">{error}</p> : null}
          {loading && events.length === 0 ? <div className="empty"><RefreshCw className="spin" /><h3>Cargando cartelera…</h3></div> : null}
          {!loading && events.length === 0 ? <div className="empty"><CalendarRange /><h3>{query ? "No encontramos coincidencias" : "La cartelera está lista para empezar"}</h3><p>{query ? "Prueba con el inicio de otro título o ciudad." : "Publica el primer evento y aparecerá aquí."}</p>{!query ? <button className="button primary" onClick={() => setEditing(null)}><Plus /> Crear evento</button> : null}</div> : null}
          <div className="event-grid">{events.map((event) => <EventCard key={event.id} event={event} onEdit={(selected) => { setFormError(null); setEditing(selected); }} onDelete={setDeleting} />)}</div>
        </section>
      </main>
      <footer className="site-footer"><strong>Eventos Cero</strong><span>React · DynamoDB · Docker · AWS</span></footer>
      {editing !== undefined ? <EventForm event={editing} isSaving={saving} error={formError} onClose={() => setEditing(undefined)} onSave={save} /> : null}
      {deleting ? <div className="confirm-backdrop"><section className="confirm" role="alertdialog" aria-modal="true"><span className="warning">!</span><h2>¿Eliminar “{deleting.title}”?</h2><p>El anuncio y su portada desaparecerán permanentemente.</p><div><button className="button secondary" onClick={() => setDeleting(null)}>Cancelar</button><button className="button danger-solid" onClick={() => void confirmDelete()}>Sí, eliminar</button></div></section></div> : null}
    </div>
  );
}
