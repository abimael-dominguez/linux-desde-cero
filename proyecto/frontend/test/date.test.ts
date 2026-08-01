import { describe, expect, it } from "vitest";
import { toDatetimeLocal, toIsoDate } from "../src/date";

describe("event date conversion", () => {
  it("round trips a local date through an ISO instant", () => {
    const local = "2026-09-10T18:30";
    expect(toDatetimeLocal(toIsoDate(local))).toBe(local);
  });
});
