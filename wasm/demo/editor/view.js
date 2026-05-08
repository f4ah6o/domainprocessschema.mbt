import { findSelectedEntity, selectedNode } from "./state.js";

export function renderGraph(state, onSelect) {
  const entity = findSelectedEntity(state);
  if (!entity) return `<p>No entity selected.</p>`;

  const renderList = (title, kind, items) => `
    <div class="graph-group">
      <strong>${title}</strong>
      <ul>
        ${items
          .map(
            (item) => `
              <li>
                <button
                  type="button"
                  data-kind="${kind}"
                  data-name="${escapeAttr(item.name)}"
                  class="${state.selection.kind === kind && state.selection.name === item.name ? "active" : ""}"
                >${escapeHtml(item.name)}</button>
              </li>`,
          )
          .join("")}
      </ul>
    </div>
  `;

  const html = `
    ${renderList("Fields", "field", entity.fields ?? [])}
    ${renderList("States", "state", entity.states ?? [])}
    ${renderList("Transitions", "transition", entity.transitions ?? [])}
    ${renderList("Views", "view", entity.views ?? [])}
    <div class="entity-meta">
      <div><strong>${escapeHtml(entity.label ?? entity.name)}</strong></div>
      <div>${escapeHtml(entity.name)}</div>
    </div>
  `;
  queueMicrotask(() => {
    const root = document.getElementById("graph");
    root?.querySelectorAll("button[data-kind]").forEach((button) => {
      button.addEventListener("click", () => {
        onSelect(button.dataset.kind, button.dataset.name);
      });
    });
  });
  return html;
}

export function renderInspector(state, onPatch) {
  const entity = findSelectedEntity(state);
  const node = selectedNode(state);
  if (!entity || !node) return `<p>Select a node.</p>`;

  if (state.selection.kind === "field") {
    return `
      ${baseHeader(entity.name, node.name)}
      ${renderTextInput("name", node.name)}
      ${renderTextInput("label", node.label ?? node.name)}
      ${renderTextInput("type", node.type)}
      ${renderTextInput("target", node.target ?? "")}
      ${renderTextInput("default", node.default ?? "")}
      ${renderTextInput("initial", node.initial ?? "")}
      ${renderCheckbox("required", node.required)}
      ${renderCheckbox("readOnly", node.readOnly)}
      ${renderCheckbox("system", node.system)}
      ${renderCheckbox("primary", node.primary)}
    `;
  }

  if (state.selection.kind === "state") {
    return `
      ${baseHeader(entity.name, node.name)}
      ${renderTextInput("name", node.name)}
      ${renderTextInput("label", node.label ?? node.name)}
      ${renderTextInput("labels.default", node.labels?.default ?? "")}
      ${renderTextInput("labels.ja", node.labels?.ja ?? "")}
    `;
  }

  if (state.selection.kind === "transition") {
    return `
      ${baseHeader(entity.name, node.name)}
      ${renderTextInput("name", node.name)}
      ${renderTextInput("from", node.from)}
      ${renderTextInput("to", node.to)}
      ${renderTextInput("role", node.role ?? "")}
      ${renderTextInput("guard", node.guard ?? "")}
      ${renderTextInput("inputsCsv", (node.inputs ?? []).map((item) => item.name).join(", "))}
    `;
  }

  return `
    ${baseHeader(entity.name, node.name)}
    ${renderTextInput("name", node.name)}
    ${renderTextInput("editableFieldsCsv", (node.editableFields ?? []).join(", "))}
    ${renderTextInput("readonlyFieldsCsv", (node.readonlyFields ?? []).join(", "))}
  `;

  function baseHeader(entityName, nodeName) {
    queueMicrotask(() => bindInspectorEvents(onPatch));
    return `<div class="inspector-form"><p><strong>${escapeHtml(entityName)}</strong> / ${escapeHtml(nodeName)}</p>`;
  }
}

export function finalizeInspectorHtml(html) {
  return `${html}</div>`;
}

function bindInspectorEvents(onPatch) {
  document.querySelectorAll("#inspector [data-field]").forEach((input) => {
    const handler = () => {
      const key = input.dataset.field;
      const value = input.type === "checkbox" ? input.checked : input.value;
      onPatch(key, value);
    };
    input.addEventListener("change", handler);
    input.addEventListener("input", handler);
  });
}

export function renderDiagnostics(diagnostics) {
  if (!diagnostics?.length) {
    return `<span class="diag-ok">No diagnostics.</span>`;
  }
  return diagnostics
    .map(
      (item) =>
        `<span class="diag-error">[${escapeHtml(item.code)}] ${escapeHtml(item.target)}: ${escapeHtml(item.message)}</span>`,
    )
    .join("\n");
}

function renderTextInput(name, value) {
  return `<label><span>${escapeHtml(name)}</span><input data-field="${escapeAttr(name)}" value="${escapeAttr(value)}" /></label>`;
}

function renderCheckbox(name, checked) {
  return `<label><span>${escapeHtml(name)}</span><input data-field="${escapeAttr(name)}" type="checkbox" ${checked ? "checked" : ""} /></label>`;
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function escapeAttr(value) {
  return escapeHtml(value).replaceAll("'", "&#39;");
}
