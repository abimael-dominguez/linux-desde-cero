import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, expect, it, vi } from "vitest";
import App from "../src/App";
import type { EventItem } from "../src/types";

const event: EventItem = {
  id: "8c2a",
  title: "Encuentro Linux",
  event_type: "Encuentro",
  description: "Una comunidad pequeña",
  starts_at: "2026-09-10T18:00:00-06:00",
  location: "Mérida",
  image_path: null,
  created_at: "2026-08-01T00:00:00Z",
  updated_at: "2026-08-01T00:00:00Z",
};

afterEach(() => {
  cleanup();
  vi.unstubAllGlobals();
});

it("searches, opens editing and confirms deletion", async () => {
  let deleted = false;
  const fetchMock = vi.fn(async (_input: string | URL | Request, init?: RequestInit) => {
    if (init?.method === "DELETE") {
      deleted = true;
      return new Response(null, { status: 204 });
    }
    return new Response(JSON.stringify(deleted ? [] : [event]), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  });
  vi.stubGlobal("fetch", fetchMock);
  render(<App />);

  expect(await screen.findByRole("heading", { name: "Encuentro Linux" })).toBeTruthy();
  fireEvent.change(screen.getByPlaceholderText("Buscar por título o ubicación"), { target: { value: "Mér" } });
  await waitFor(() => expect(fetchMock.mock.calls.some(([input]) => String(input).includes("q=M%C3%A9r"))).toBe(true), { timeout: 1000 });

  fireEvent.click(screen.getByRole("button", { name: "Editar" }));
  expect(screen.getByRole("heading", { name: "Editar evento" })).toBeTruthy();
  fireEvent.click(screen.getByRole("button", { name: "Cerrar" }));

  fireEvent.click(screen.getByRole("button", { name: "Eliminar Encuentro Linux" }));
  expect(screen.getByRole("heading", { name: /Eliminar “Encuentro Linux”/ })).toBeTruthy();
  fireEvent.click(screen.getByRole("button", { name: "Sí, eliminar" }));
  await waitFor(() => expect(deleted).toBe(true));
  await waitFor(() => expect(screen.queryByRole("heading", { name: "Encuentro Linux" })).toBeNull());
});

it("opens the creation form", async () => {
  vi.stubGlobal("fetch", vi.fn(async () => new Response("[]", { status: 200, headers: { "Content-Type": "application/json" } })));
  render(<App />);
  await screen.findByText("La cartelera está lista para empezar");
  fireEvent.click(screen.getByRole("button", { name: "Publicar evento" }));
  expect(screen.getByRole("heading", { name: "Nuevo evento" })).toBeTruthy();
});
