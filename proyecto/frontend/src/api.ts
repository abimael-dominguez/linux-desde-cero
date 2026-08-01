import { toIsoDate } from "./date";
import type { EventFormValues, EventItem } from "./types";

const API_PATH = "/api/events";

export async function fetchEvents(query: string): Promise<EventItem[]> {
  const url = new URL(API_PATH, window.location.origin);
  if (query.trim()) url.searchParams.set("q", query.trim());
  return request<EventItem[]>(url.toString());
}

export async function saveEvent(
  id: string | null,
  values: EventFormValues,
  cover: File | null,
  removeCover: boolean,
): Promise<EventItem> {
  const form = new FormData();
  form.set("title", values.title);
  form.set("event_type", values.eventType);
  form.set("description", values.description);
  form.set("starts_at", toIsoDate(values.startsAt));
  form.set("location", values.location);
  form.set("remove_cover", String(removeCover));
  if (cover) form.set("cover", cover);
  return request<EventItem>(id ? `${API_PATH}/${id}` : API_PATH, {
    method: id ? "PUT" : "POST",
    body: form,
  });
}

export async function deleteEvent(id: string): Promise<void> {
  await request<void>(`${API_PATH}/${id}`, { method: "DELETE" });
}

async function request<T>(url: string, init?: RequestInit): Promise<T> {
  const response = await fetch(url, init);
  if (!response.ok) {
    let message = "No pudimos completar la solicitud.";
    try {
      const body = (await response.json()) as { detail?: unknown };
      if (typeof body.detail === "string") message = body.detail;
      if (Array.isArray(body.detail)) message = "Revisa los campos del formulario.";
    } catch {
      // Keep the friendly fallback when the origin returns a non-JSON error.
    }
    throw new Error(message);
  }
  if (response.status === 204) return undefined as T;
  return response.json() as Promise<T>;
}
