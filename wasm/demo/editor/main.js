import { postEditorJson } from "./http-client.js";
import { loadPersistedSource, savePersistedSource } from "./persistence.js";
import {
  cloneModel,
  createFieldDraft,
  createInitialState,
  createStateDraft,
  createTransitionDraft,
  createViewDraft,
  emitSchemaYaml,
  ensureSelection,
  findSelectedEntity,
  preferredEntityName,
  readNormalizedPayload,
  selectedNode,
  updateSelectedEntity,
  updateSelection,
} from "./state.js";
import { finalizeInspectorHtml, renderDiagnostics, renderGraph, renderInspector } from "./view.js";
import { registerModelContextTools, runWithUserInteraction } from "./webmcp.js";

const state = createInitialState();

const sourceEl = document.getElementById("source");
const statusEl = document.getElementById("status");
const diagnosticsEl = document.getElementById("diagnostics");
const graphEl = document.getElementById("graph");
const inspectorEl = document.getElementById("inspector");
const previewEl = document.getElementById("preview");
const entitySelectEl = document.getElementById("entity-select");
const actorRoleEl = document.getElementById("actor-role");
const compileButton = document.getElementById("compile-button");
const resetButton = document.getElementById("reset-button");
const exportButton = document.getElementById("export-button");

actorRoleEl.addEventListener("change", async () => {
  state.actorRole = actorRoleEl.value;
  await refreshRuntimePreview();
  render();
});

entitySelectEl.addEventListener("change", () => {
  updateSelectedEntity(state, entitySelectEl.value);
  render();
});

sourceEl.addEventListener("input", () => {
  state.source = sourceEl.value;
  savePersistedSource(state.source);
});

compileButton.addEventListener("click", async () => {
  await compileCurrentSource();
});

resetButton.addEventListener("click", async () => {
  const response = await fetch("../examples/expense_request.yaml");
  state.source = await response.text();
  sourceEl.value = state.source;
  savePersistedSource(state.source);
  state.runtimeRecord = null;
  await compileCurrentSource();
});

exportButton.addEventListener("click", async () => {
  const text = state.emittedYaml || state.source;
  await navigator.clipboard.writeText(text);
  setStatus("Copied emitted YAML to clipboard.");
});

document.getElementById("add-field").addEventListener("click", () => addNode("field"));
document.getElementById("add-state").addEventListener("click", () => addNode("state"));
document.getElementById("add-transition").addEventListener("click", () => addNode("transition"));
document.getElementById("add-view").addEventListener("click", () => addNode("view"));

const disposeWebMcp = registerModelContextTools(createTools());
void disposeWebMcp;

boot().catch((error) => {
  setStatus(error instanceof Error ? error.message : String(error));
});

async function boot() {
  state.source = loadPersistedSource();
  if (!state.source) {
    const response = await fetch("../examples/expense_request.yaml");
    state.source = await response.text();
  }
  sourceEl.value = state.source;
  actorRoleEl.value = state.actorRole;
  await compileCurrentSource();
}

async function compileCurrentSource() {
  setStatus("Compiling schema…");
  const result = await postEditorJson("compile", {
    source: state.source,
    locale: "en",
  });
  state.diagnostics = result.diagnostics ?? [];
  if (!result.ok) {
    state.model = null;
    state.entities = [];
    state.previewHtml = "";
    state.runtimeView = null;
    previewEl.srcdoc = "";
    render();
    setStatus("Compile failed.");
    return;
  }

  state.emittedYaml = result.emittedYaml ?? state.source;
  state.model = cloneModel(readNormalizedPayload(result));
  state.entities = result.entities ?? [];
  const currentEntityKnown = state.model?.entities?.some((entity) => entity.name === state.selectedEntityName);
  if (!state.selectedEntityName || !currentEntityKnown) {
    state.selectedEntityName = preferredEntityName(state.model);
  }
  ensureSelection(state);
  syncEntitySelect();
  await refreshRuntimePreview();
  render();
  setStatus("Compile succeeded.");
}

async function refreshRuntimePreview() {
  if (!state.source) return;
  const result = await postEditorJson("runtime-preview", {
    source: state.source,
    actorRole: state.actorRole,
    record: state.runtimeRecord,
    locale: "en",
  });
  if (result.record) {
    state.runtimeRecord = result.record;
  }
  state.runtimeView = result.view ?? null;
  state.previewHtml = result.previewHtml ?? "";
  if (Array.isArray(result.diagnostics) && result.diagnostics.length > 0) {
    state.diagnostics = result.diagnostics;
  }
  render();
}

function render() {
  syncEntitySelect();
  graphEl.innerHTML = renderGraph(state, (kind, name) => {
    updateSelection(state, kind, name);
    render();
  });
  inspectorEl.innerHTML = finalizeInspectorHtml(
    renderInspector(state, async (field, value) => {
      applyInspectorPatch(field, value);
      await commitVisualEdit();
    }),
  );
  diagnosticsEl.textContent = renderDiagnostics(state.diagnostics);
  previewEl.srcdoc = state.previewHtml || `<p>Preview unavailable.</p>`;
}

function syncEntitySelect() {
  const current = state.selectedEntityName;
  entitySelectEl.innerHTML = (state.entities ?? [])
    .map(
      (entity) =>
        `<option value="${entity.name}" ${entity.name === current ? "selected" : ""}>${entity.label ?? entity.name}</option>`,
    )
    .join("");
}

function applyInspectorPatch(field, value) {
  const entity = findSelectedEntity(state);
  const node = selectedNode(state);
  if (!entity || !node) return;

  if (field === "inputsCsv") {
    node.inputs = value
      .split(",")
      .map((item) => item.trim())
      .filter(Boolean)
      .map((name) => ({
        name,
        kind: entity.fields.some((candidate) => candidate.name === name) ? "entity-field" : "local",
        type: entity.fields.find((candidate) => candidate.name === name)?.type ?? "text",
        required: entity.fields.find((candidate) => candidate.name === name)?.required ?? false,
        readOnly: false,
        default: null,
        target: entity.fields.find((candidate) => candidate.name === name)?.target ?? null,
      }));
    return;
  }

  if (field === "editableFieldsCsv" || field === "readonlyFieldsCsv") {
    node[field === "editableFieldsCsv" ? "editableFields" : "readonlyFields"] = value
      .split(",")
      .map((item) => item.trim())
      .filter(Boolean);
    return;
  }

  if (field.startsWith("labels.")) {
    node.labels = node.labels ?? {};
    const labelKey = field.slice("labels.".length);
    if (!value) {
      delete node.labels[labelKey];
    } else {
      node.labels[labelKey] = value;
    }
    return;
  }

  if (typeof value === "boolean") {
    node[field] = value;
  } else {
    node[field] = value === "" ? nullishField(field) : value;
  }
}

function nullishField(field) {
  return ["target", "default", "initial", "role", "guard"].includes(field) ? null : "";
}

async function commitVisualEdit() {
  if (!state.model) return;
  state.source = emitSchemaYaml(state.model);
  state.runtimeRecord = null;
  sourceEl.value = state.source;
  savePersistedSource(state.source);
  await compileCurrentSource();
}

function addNode(kind) {
  const entity = findSelectedEntity(state);
  if (!entity || !state.model) return;

  if (kind === "field") {
    const next = createFieldDraft(entity);
    entity.fields.push(next);
    state.selection = { kind, name: next.name };
  } else if (kind === "state") {
    const next = createStateDraft(entity);
    entity.states.push(next);
    state.selection = { kind, name: next.name };
  } else if (kind === "transition") {
    const next = createTransitionDraft(entity);
    entity.transitions.push(next);
    state.selection = { kind, name: next.name };
  } else {
    const next = createViewDraft(entity);
    entity.views.push(next);
    state.selection = { kind, name: next.name };
  }

  void commitVisualEdit();
}

function createTools() {
  return [
    {
      name: "domainprocessschema-get-editor-state",
      title: "Get domainprocessschema editor state",
      description: "Returns the current YAML source, selected entity, actor role, diagnostics, and runtime preview state.",
      inputSchema: { type: "object", properties: {} },
      annotations: { readOnlyHint: true },
      execute: async () => ({
        source: state.source,
        emittedYaml: state.emittedYaml,
        actorRole: state.actorRole,
        selectedEntityName: state.selectedEntityName,
        selection: state.selection,
        entities: state.entities,
        diagnostics: state.diagnostics,
        runtimeRecord: state.runtimeRecord,
      }),
    },
    {
      name: "domainprocessschema-set-source",
      title: "Set domainprocessschema source",
      description: "Replaces the YAML source and recompiles the editor.",
      inputSchema: {
        type: "object",
        properties: { source: { type: "string" } },
        required: ["source"],
      },
      execute: async (input, client) =>
        runWithUserInteraction(client, async () => {
          state.source = String(input.source ?? "");
          state.runtimeRecord = null;
          sourceEl.value = state.source;
          savePersistedSource(state.source);
          await compileCurrentSource();
          return { ok: state.diagnostics.length === 0, diagnostics: state.diagnostics };
        }),
    },
    {
      name: "domainprocessschema-validate-source",
      title: "Validate domainprocessschema source",
      description: "Compiles the current YAML source and returns diagnostics.",
      inputSchema: { type: "object", properties: {} },
      annotations: { readOnlyHint: true },
      execute: async () => {
        const result = await postEditorJson("compile", { source: state.source, locale: "en" });
        return { ok: Boolean(result.ok), diagnostics: result.diagnostics ?? [] };
      },
    },
    {
      name: "domainprocessschema-render-preview",
      title: "Render domainprocessschema runtime preview",
      description: "Renders the current runtime preview for the selected actor role.",
      inputSchema: { type: "object", properties: {} },
      annotations: { readOnlyHint: true },
      execute: async () => {
        const result = await postEditorJson("runtime-preview", {
          source: state.source,
          actorRole: state.actorRole,
          record: state.runtimeRecord,
          locale: "en",
        });
        return {
          ok: Boolean(result.ok),
          diagnostics: result.diagnostics ?? [],
          record: result.record ?? null,
          view: result.view ?? null,
        };
      },
    },
    {
      name: "domainprocessschema-export-source",
      title: "Export domainprocessschema source",
      description: "Returns the current canonical YAML source.",
      inputSchema: { type: "object", properties: {} },
      annotations: { readOnlyHint: true },
      execute: async () => ({
        source: state.source,
        emittedYaml: state.emittedYaml || state.source,
      }),
    },
    {
      name: "domainprocessschema-set-actor-role",
      title: "Set domainprocessschema actor role",
      description: "Updates the runtime preview actor role and rerenders the preview.",
      inputSchema: {
        type: "object",
        properties: { actorRole: { type: "string" } },
      },
      execute: async (input, client) =>
        runWithUserInteraction(client, async () => {
          state.actorRole = String(input.actorRole ?? "");
          actorRoleEl.value = state.actorRole;
          await refreshRuntimePreview();
          return { actorRole: state.actorRole, diagnostics: state.diagnostics };
        }),
    },
    {
      name: "domainprocessschema-apply-transition",
      title: "Apply domainprocessschema transition",
      description: "Applies a transition to the current runtime record and updates the preview.",
      inputSchema: {
        type: "object",
        properties: {
          transitionName: { type: "string" },
          input: { type: "object" },
        },
        required: ["transitionName"],
      },
      execute: async (input, client) =>
        runWithUserInteraction(client, async () => {
          const result = await postEditorJson("apply-transition", {
            source: state.source,
            actorRole: state.actorRole,
            record: state.runtimeRecord,
            transitionName: String(input.transitionName),
            input: input.input ?? {},
            locale: "en",
          });
          state.runtimeRecord = result.record ?? state.runtimeRecord;
          state.runtimeView = result.view ?? null;
          state.previewHtml = result.previewHtml ?? "";
          state.diagnostics = result.diagnostics ?? [];
          render();
          return result;
        }),
    },
    {
      name: "domainprocessschema-list-entities",
      title: "List domainprocessschema entities",
      description: "Lists entity names and labels from the current compile result.",
      inputSchema: { type: "object", properties: {} },
      annotations: { readOnlyHint: true },
      execute: async () => state.entities,
    },
  ];
}

function setStatus(message) {
  statusEl.textContent = message;
}
