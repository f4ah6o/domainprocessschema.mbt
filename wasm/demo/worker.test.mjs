import assert from "node:assert/strict";
import fs, { readFile } from "node:fs/promises";
import test from "node:test";

import worker, { handleRequest } from "./worker.mjs";

const yaml = await fs.readFile(new URL("../../examples/expense_request.yaml", import.meta.url), "utf8");

const assets = {
  fetch: async () => new Response("asset"),
};

function createEnv() {
  return {
    ASSETS: {
      fetch: async () => new Response("asset", { status: 200 }),
    },
  };
}

async function postJson(path, body) {
  const response = await handleRequest(
    new Request(`https://example.test/api/editor/${path}`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(body),
    }),
    createEnv(),
  );
  return {
    status: response.status,
    json: JSON.parse(await response.text()),
  };
}

test("compile route returns editor payload", async () => {
  const result = await postJson("compile", { source: yaml, locale: "en" });
  assert.equal(result.status, 200);
  assert.equal(result.json.ok, true);
  assert.equal(result.json.entities.at(-1)?.name, "ExpenseRequest");
  assert.match(result.json.emittedYaml, /softDelete: true/);
  assert.equal(
    result.json.normalizedSchema.payload.entities[1].fields.find((field) => field.name === "status").initial,
    "draft",
  );
});

test("runtime-preview route renders the draft expense request view", async () => {
  const result = await postJson("runtime-preview", {
    source: yaml,
    actorRole: "applicant",
    locale: "en",
  });
  assert.equal(result.status, 200);
  assert.equal(result.json.ok, true);
  assert.equal(result.json.record.entityName, "ExpenseRequest");
  assert.equal(result.json.view.state, "draft");
  assert.match(result.json.previewHtml, /Expense Request - Draft/);
});

test("runtime-preview treats null record as missing record", async () => {
  const result = await postJson("runtime-preview", {
    source: yaml,
    actorRole: "applicant",
    record: null,
    locale: "en",
  });
  assert.equal(result.status, 200);
  assert.equal(result.json.ok, true);
  assert.equal(result.json.record.entityName, "ExpenseRequest");
  assert.equal(result.json.view.state, "draft");
  assert.match(result.json.previewHtml, /Expense Request - Draft/);
});

test("apply-transition route advances to submitted", async () => {
  const preview = await postJson("runtime-preview", {
    source: yaml,
    actorRole: "applicant",
    locale: "en",
  });
  const result = await postJson("apply-transition", {
    source: yaml,
    transitionName: "submit",
    actorRole: "applicant",
    record: preview.json.record,
    input: {
      amount: 1200,
      reason: "Taxi",
      applicant: "user-1",
    },
    locale: "en",
  });
  assert.equal(result.status, 200);
  assert.equal(result.json.ok, true);
  assert.equal(result.json.record.values.status, "submitted");
  assert.equal(result.json.view.state, "submitted");
  assert.match(result.json.previewHtml, /Expense Request - Submitted/);
});

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
