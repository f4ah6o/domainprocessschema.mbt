import assert from "node:assert/strict";
import fs from "node:fs/promises";
import test from "node:test";

import { handleRequest } from "./worker.mjs";

const yaml = await fs.readFile(new URL("../../examples/expense_request.yaml", import.meta.url), "utf8");

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
