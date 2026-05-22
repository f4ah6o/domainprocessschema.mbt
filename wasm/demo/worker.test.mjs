import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import worker from "./worker.mjs";

const assets = {
  fetch: async () => new Response("asset"),
};

test("worker health endpoint returns stable json envelope", async () => {
  const response = await worker.fetch(new Request("https://example.test/api/health"), {
    ASSETS: assets,
  });
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { ok: true, version: 1 });
});

test("worker API rejects oversized schema requests", async () => {
  const response = await worker.fetch(
    new Request("https://example.test/api/schema/compile", {
      method: "POST",
      headers: { "content-length": String(65 * 1024) },
      body: "{}",
    }),
    { ASSETS: assets },
  );
  const body = await response.json();
  assert.equal(response.status, 413);
  assert.equal(body.ok, false);
  assert.equal(body.error.code, "REQUEST_TOO_LARGE");
  assert.equal(body.error.details.maxBytes, 64 * 1024);
});

test("worker API rejects oversized streamed schema requests", async () => {
  const response = await worker.fetch(
    new Request("https://example.test/api/schema/compile", {
      method: "POST",
      body: JSON.stringify({ sourceYaml: "x".repeat(65 * 1024) }),
    }),
    { ASSETS: assets },
  );
  const body = await response.json();
  assert.equal(response.status, 413);
  assert.equal(body.error.code, "REQUEST_TOO_LARGE");
});

test("worker API rejects malformed json with stable envelope", async () => {
  const response = await worker.fetch(
    new Request("https://example.test/api/schema/compile", {
      method: "POST",
      body: "{",
    }),
    { ASSETS: assets },
  );
  const body = await response.json();
  assert.equal(response.status, 400);
  assert.equal(body.error.code, "BAD_JSON");
});

test("worker delegates normal asset requests to Cloudflare Assets binding", async () => {
  const response = await worker.fetch(new Request("https://example.test/"), {
    ASSETS: assets,
  });
  assert.equal(await response.text(), "asset");
  assert.equal(response.headers.get("x-content-type-options"), "nosniff");
});

test("worker redirects /demo to /demo/", async () => {
  const response = await worker.fetch(new Request("https://example.test/demo"), {
    ASSETS: assets,
  });
  assert.equal(response.status, 308);
  assert.equal(response.headers.get("location"), "https://example.test/demo/");
});

test("wrangler routes browser app assets through the Worker", async () => {
  const wrangler = JSON.parse(await readFile(new URL("../../wrangler.jsonc", import.meta.url), "utf8"));
  assert.deepEqual(wrangler.assets.run_worker_first, [
    "/",
    "/api/*",
    "/demo",
    "/demo/*",
    "/demo.wasm",
    "/editor/app.css",
    "/main.js",
  ]);
});
