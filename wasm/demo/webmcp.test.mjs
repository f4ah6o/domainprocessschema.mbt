import assert from "node:assert/strict";
import test from "node:test";

import { registerModelContextTools, runWithUserInteraction } from "./editor/webmcp.js";

test("registerModelContextTools registers all tools and disposes them", () => {
  const registrations = [];
  const aborted = [];
  const priorNavigator = globalThis.navigator;

  Object.defineProperty(globalThis, "navigator", {
    configurable: true,
    value: {
      modelContext: {
        registerTool(tool, { signal }) {
          registrations.push(tool.name);
          signal.addEventListener("abort", () => aborted.push(tool.name));
        },
      },
    },
  });

  const dispose = registerModelContextTools([{ name: "alpha" }, { name: "beta" }]);
  assert.deepEqual(registrations, ["alpha", "beta"]);
  dispose();
  assert.deepEqual(aborted, ["alpha", "beta"]);

  Object.defineProperty(globalThis, "navigator", {
    configurable: true,
    value: priorNavigator,
  });
});

test("runWithUserInteraction delegates through requestUserInteraction when present", async () => {
  const calls = [];
  const result = await runWithUserInteraction(
    {
      requestUserInteraction(fn) {
        calls.push("requested");
        fn();
      },
    },
    async () => {
      calls.push("executed");
      return 42;
    },
  );

  assert.equal(result, 42);
  assert.deepEqual(calls, ["requested", "executed"]);
});
