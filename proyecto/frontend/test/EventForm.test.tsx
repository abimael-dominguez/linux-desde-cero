import { cleanup, fireEvent, render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { EventForm } from "../src/EventForm";
import type { EventItem } from "../src/types";

const event: EventItem = {
  id: "1",
  title: "Taller Linux",
  event_type: "Taller",
  description: "Terminal para todos",
  starts_at: "2026-09-10T18:00:00-06:00",
  location: "Puebla",
  image_path: "/media/events/1/cover.webp",
  created_at: "2026-08-01T00:00:00Z",
  updated_at: "2026-08-01T00:00:00Z",
};

afterEach(cleanup);

describe("EventForm", () => {
  it("supports creation, instant preview and file selection", () => {
    const save = vi.fn(async () => undefined);
    Object.defineProperty(URL, "createObjectURL", { configurable: true, value: vi.fn(() => "blob:preview") });
    Object.defineProperty(URL, "revokeObjectURL", { configurable: true, value: vi.fn() });
    render(<EventForm event={null} isSaving={false} error={null} onClose={() => undefined} onSave={save} />);

    fireEvent.change(screen.getByLabelText("Título"), { target: { value: "Festival del código" } });
    fireEvent.change(screen.getByLabelText("Ubicación"), { target: { value: "Oaxaca" } });
    fireEvent.change(screen.getByLabelText(/Descripción/), { target: { value: "Una tarde de comunidad" } });
    expect(screen.getByRole("heading", { name: "Festival del código" })).toBeTruthy();
    expect(screen.getByText("Una tarde de comunidad", { selector: ".preview-copy p" })).toBeTruthy();

    const cover = new File(["cover"], "cover.webp", { type: "image/webp" });
    fireEvent.change(screen.getByLabelText(/Seleccionar portada/), { target: { files: [cover] } });
    expect(screen.getByAltText("Vista previa de portada").getAttribute("src")).toBe("blob:preview");
  });

  it("loads an existing event for editing", () => {
    render(<EventForm event={event} isSaving={false} error={null} onClose={() => undefined} onSave={async () => undefined} />);
    expect(screen.getByRole("heading", { name: "Editar evento" })).toBeTruthy();
    expect((screen.getByLabelText("Título") as HTMLInputElement).value).toBe("Taller Linux");
    expect(screen.getByAltText("Vista previa de portada").getAttribute("src")).toBe(event.image_path);
  });
});
