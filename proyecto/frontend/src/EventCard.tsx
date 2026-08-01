import { CalendarDays, Clock3, MapPin, Pencil, Trash2 } from "lucide-react";
import { formatEventDate } from "./date";
import type { EventItem } from "./types";

type EventCardProps = {
  event: EventItem;
  onEdit: (event: EventItem) => void;
  onDelete: (event: EventItem) => void;
};

export function EventCard({ event, onEdit, onDelete }: EventCardProps): JSX.Element {
  const isPast = new Date(event.starts_at).getTime() < Date.now();
  return (
    <article className="event-card">
      <div className={`event-cover ${event.image_path ? "has-image" : ""}`}>
        {event.image_path ? <img src={event.image_path} alt="" /> : null}
        <span className="event-type">{event.event_type}</span>
        <span className={`event-state ${isPast ? "past" : "upcoming"}`}>
          {isPast ? "Finalizado" : "Próximamente"}
        </span>
      </div>
      <div className="event-body">
        <p className="eyebrow"><CalendarDays size={14} /> Evento publicado</p>
        <h2>{event.title}</h2>
        <p className="event-description">
          {event.description || "Una experiencia preparada para compartir en comunidad."}
        </p>
        <dl className="event-meta">
          <div><Clock3 size={17} /><dd>{formatEventDate(event.starts_at)}</dd></div>
          <div><MapPin size={17} /><dd>{event.location}</dd></div>
        </dl>
        <div className="event-actions">
          <button className="button secondary" onClick={() => onEdit(event)}>
            <Pencil size={16} /> Editar
          </button>
          <button className="icon-button danger" onClick={() => onDelete(event)} aria-label={`Eliminar ${event.title}`}>
            <Trash2 size={18} />
          </button>
        </div>
      </div>
    </article>
  );
}
