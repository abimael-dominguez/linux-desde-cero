import react from "@vitejs/plugin-react";
import { loadEnv } from "vite";
import { defineConfig } from "vitest/config";

export default defineConfig(({ mode }) => {
  const backend = process.env.VITE_BACKEND_ORIGIN || loadEnv(mode, process.cwd(), "").VITE_BACKEND_ORIGIN || "http://127.0.0.1:8000";
  return {
    plugins: [react()],
    test: {
      environment: "jsdom",
    },
    server: {
      port: 5173,
      proxy: {
        "/api": backend,
        "/media": backend,
      },
    },
  };
});
