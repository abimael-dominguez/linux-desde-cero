import { ImagePlus, MapPin, Save, X } from "lucide-react";
import { useEffect, useMemo, useState, type FormEvent } from "react";
import { formatEventDate, toDatetimeLocal } from "./date";
import type { EventFormValues, EventItem } from "./types";

const MAX_COVER_BYTES = 2 * 1024 * 1024;

type EventFormProps = {
  event: EventItem | null;
  isSaving: boolean;
  error: string | null;
  onClose: () => void;
  onSave: (values: EventFormValues, cover: File | null, removeCover: boolean) => Promise<void>;
};

const emptyValues = (): EventFormValues => ({
  title: "",
  eventType: "Encuentro",
  description: "",
  startsAt: toDatetimeLocal(new Date(Date.now() + 86_400_000).toISOString()),
  location: "",
});

export function EventForm({ event, isSaving, error, onClose, onSave }: EventFormProps): JSX.Element {
  const [values, setValues] = useState<EventFormValues>(emptyValues);
  const [cover, setCover] = useState<File | null>(null);
  const [removeCover, setRemoveCover] = useState(false);
  const [fileError, setFileError] = useState<string | null>(null);

  useEffect(() => {
    setValues(event ? {
      title: event.title,
      eventType: event.event_type,
      description: event.description,
      startsAt: toDatetimeLocal(event.starts_at),
      location: event.location,
    } : emptyValues());
    setCover(null);
    setRemoveCover(false);
    setFileError(null);
  }, [event]);

  const preview = useMemo(() => cover ? URL.createObjectURL(cover) : (!removeCover ? event?.image_path ?? null : null), [cover, event, removeCover]);
  useEffect(() => () => { if (cover && preview) URL.revokeObjectURL(preview); }, [cover, preview]);

  function set<K extends keyof EventFormValues>(key: K, value: EventFormValues[K]): void {
    setValues((current) => ({ ...current, [key]: value }));
  }

  function selectCover(file: File | undefined): void {
    if (!file) return;
    if (!file.type.match(/^image\/(jpeg|png|webp)$/) || file.size > MAX_COVER_BYTES) {
      setFileError("Usa una imagen JPG, PNG o WebP de máximo 2 MiB.");
      return;
    }
    setFileError(null);
    setCover(file);
    setRemoveCover(false);
  }

  async function submit(eventSubmit: FormEvent): Promise<void> {
    eventSubmit.preventDefault();
    await onSave(values, cover, removeCover);
  }

  return (
    <div className="editor-backdrop" role="presentation">
      <section className="editor" role="dialog" aria-modal="true" aria-labelledby="editor-title">
        <header className="editor-header">
          <div><p className="eyebrow">Publicación</p><h2 id="editor-title">{event ? "Editar evento" : "Nuevo evento"}</h2></div>
          <button className="icon-button" onClick={onClose} aria-label="Cerrar"><X /></button>
        </header>
        <div className="editor-grid">
          <form id="event-form" onSubmit={submit} className="event-form">
            <label><span>Título</span><input required minLength={3} maxLength={120} value={values.title} onChange={(e) => set("title", e.target.value)} placeholder="Ej. Linux bajo las estrellas" /></label>
            <div className="form-row">
              <label><span>Tipo</span><input required minLength={3} maxLength={60} value={values.eventType} onChange={(e) => set("eventType", e.target.value)} /></label>
              <label><span>Fecha y hora</span><input required type="datetime-local" value={values.startsAt} onChange={(e) => set("startsAt", e.target.value)} /></label>
            </div>
            <label><span>Ubicación</span><div className="input-icon"><MapPin size={17} /><input required minLength={3} maxLength={160} value={values.location} onChange={(e) => set("location", e.target.value)} placeholder="Ciudad o sede" /></div></label>
            <label><span>Descripción</span><textarea rows={4} maxLength={600} value={values.description} onChange={(e) => set("description", e.target.value)} placeholder="Una descripción breve y memorable." /><small>{values.description.length}/600</small></label>
            <label className="upload"><ImagePlus /><span><strong>Seleccionar portada</strong><small>JPG, PNG o WebP · máximo 2 MiB</small></span><input type="file" accept="image/jpeg,image/png,image/webp" onChange={(e) => selectCover(e.target.files?.[0])} /></label>
            {(preview || cover) ? <button type="button" className="text-button" onClick={() => { setCover(null); setRemoveCover(true); }}>Quitar portada</button> : null}
            {fileError ? <p className="feedback error">{fileError}</p> : null}
            {error ? <p className="feedback error">{error}</p> : null}
          </form>
          <aside className="live-preview">
            <p className="eyebrow">Vista previa</p>
            <div className="preview-card">
              <div className="preview-cover">{preview ? <img src={preview} alt="Vista previa de portada" /> : <ImagePlus size={34} />}<span>{values.eventType || "Evento"}</span></div>
              <div className="preview-copy"><h3>{values.title || "Tu evento aparecerá aquí"}</h3><p>{values.description || "Agrega una descripción para presentar la experiencia."}</p><strong>{values.startsAt ? formatEventDate(new Date(values.startsAt).toISOString()) : "Fecha por definir"}</strong><small>{values.location || "Ubicación por definir"}</small></div>
            </div>
          </aside>
        </div>
        <footer className="editor-footer"><button className="button secondary" onClick={onClose}>Cancelar</button><button className="button primary" type="submit" form="event-form" disabled={isSaving}><Save size={17} />{isSaving ? "Guardando…" : "Publicar cambios"}</button></footer>
      </section>
    </div>
  );
}
