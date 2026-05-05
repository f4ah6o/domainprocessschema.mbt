const wasmUrl = "../../_build/wasm-gc/release/build/wasm/demo/demo.wasm";
const yamlUrl = "../../examples/expense_request.yaml";

const statusNode = document.getElementById("status");
const validationNode = document.getElementById("validation");
const previewNode = document.getElementById("preview");
const yamlNode = document.getElementById("yaml");
const localeNode = document.getElementById("locale");
const actorRoleNode = document.getElementById("actor-role");
const renderButton = document.getElementById("render");
const resetButton = document.getElementById("reset");
const pageTitleNode = document.getElementById("page-title");
const pageDescriptionNode = document.getElementById("page-description");
const yamlLabelNode = document.getElementById("yaml-label");
const actorRoleLabelNode = document.getElementById("actor-role-label");
const localeLabelNode = document.getElementById("locale-label");
const validationSummaryNode = document.getElementById("validation-summary");
const currentViewHeadingNode = document.getElementById("current-view-heading");
const currentViewNode = document.getElementById("current-view");
const actionsHeadingNode = document.getElementById("actions-heading");
const actionsNode = document.getElementById("actions");

let api = null;
let exampleYamlText = "";
let currentLocale = "en";
let currentSession = null;
let currentSnapshot = null;
let currentValidationLookup = null;
let currentReferenceCatalog = null;

// Keep the last failing payload per action so rerenders can preserve the user's
// input values and show the failure inline instead of only in the global status.
const actionFailures = new Map();

const translations = {
  en: {
    pageTitle: "domainprocessschema.mbt MoonBit WASM demo",
    pageDescription:
      'This page loads the MoonBit WASM build, fetches <code>examples/expense_request.yaml</code>, and lets you execute transitions from a live runtime session in the browser host.',
    yamlLabel: "YAML source",
    actorRoleLabel: "Actor role",
    localeLabel: "Language",
    currentViewHeading: "Current view",
    renderButton: "Start runtime session",
    resetButton: "Reset example",
    noCurrentView: "Start a runtime session to inspect the structured current view.",
    noCurrentViewFields: "The current view has no visible fields.",
    stateMetaLabel: "state",
    viewNameMetaLabel: "view",
    emptyValue: "(empty)",
    actionsHeading: "Available transitions",
    validationSummary: "validation manifest",
    loading: "Loading WASM demo…",
    fetching: "Fetching schema and WASM module…",
    wasmNotLoaded: "WASM module is not loaded yet.",
    sessionReady: (state) => `Rendered runtime state: ${state}`,
    transitionApplied: (name) => `Applied transition: ${name}`,
    noActions: "No transitions are currently available.",
    applyAction: "Apply transition",
    previewTitle: "MoonBit WASM preview",
    validationLoading: "Loading validation manifest…",
    guardLabel: "guard",
    inputKindEntityField: "entity field",
    inputKindLocal: "local input",
    readOnlyTag: "read-only",
    systemTag: "system",
    targetTag: "target",
    defaultTag: "default",
    referencePlaceholder: "Select a reference…",
    lastErrorLabel: "Last error",
    lastPayloadLabel: "Last payload",
    errorKindLabel: "kind",
    issuesLabel: "Issues",
    actorRoles: {
      "": "anonymous",
      manager: "manager",
    },
  },
  ja: {
    pageTitle: "domainprocessschema.mbt MoonBit WASM デモ",
    pageDescription:
      '<code>examples/expense_request.yaml</code> を読み込み、MoonBit WASM build を使って browser host から transition を実行し、runtime preview を再描画します。',
    yamlLabel: "YAML ソース",
    actorRoleLabel: "Actor role",
    localeLabel: "表示言語",
    currentViewHeading: "現在の view",
    renderButton: "runtime session を開始",
    resetButton: "example を戻す",
    noCurrentView: "runtime session を開始すると、structured current view をここに表示します。",
    noCurrentViewFields: "現在の view に visible field はありません。",
    stateMetaLabel: "state",
    viewNameMetaLabel: "view",
    emptyValue: "(empty)",
    actionsHeading: "利用可能 transition",
    validationSummary: "validation manifest",
    loading: "WASM デモを読み込み中…",
    fetching: "schema と WASM module を取得中…",
    wasmNotLoaded: "WASM module がまだ読み込まれていません。",
    sessionReady: (state) => `描画した runtime state: ${state}`,
    transitionApplied: (name) => `実行した transition: ${name}`,
    noActions: "現在実行できる transition はありません。",
    applyAction: "transition を実行",
    previewTitle: "MoonBit WASM プレビュー",
    validationLoading: "validation manifest を読み込み中…",
    guardLabel: "guard",
    inputKindEntityField: "entity field",
    inputKindLocal: "local input",
    readOnlyTag: "read-only",
    systemTag: "system",
    targetTag: "target",
    defaultTag: "default",
    referencePlaceholder: "reference を選択…",
    lastErrorLabel: "直前の error",
    lastPayloadLabel: "直前の payload",
    errorKindLabel: "kind",
    issuesLabel: "Issues",
    actorRoles: {
      "": "anonymous",
      manager: "manager",
    },
  },
};

function t() {
  return translations[currentLocale];
}

function applyLocale() {
  const text = t();
  document.documentElement.lang = currentLocale;
  document.title = text.pageTitle;
  pageTitleNode.textContent = text.pageTitle;
  pageDescriptionNode.innerHTML = text.pageDescription;
  yamlLabelNode.textContent = text.yamlLabel;
  actorRoleLabelNode.textContent = text.actorRoleLabel;
  localeLabelNode.textContent = text.localeLabel;
  currentViewHeadingNode.textContent = text.currentViewHeading;
  renderButton.textContent = text.renderButton;
  resetButton.textContent = text.resetButton;
  actionsHeadingNode.textContent = text.actionsHeading;
  validationSummaryNode.textContent = text.validationSummary;
  previewNode.title = text.previewTitle;
  validationNode.textContent = text.validationLoading;
  if (!currentSnapshot) {
    currentViewNode.innerHTML = `<p>${escapeHtml(text.noCurrentView)}</p>`;
  }
  for (const option of actorRoleNode.options) {
    option.textContent = text.actorRoles[option.value] ?? option.value;
  }
}

async function loadWasm() {
  const { instance } = await WebAssembly.instantiateStreaming(
    fetch(wasmUrl),
    { _: {} },
    {
      builtins: ["js-string"],
      importedStringConstants: "_",
    },
  );
  return instance.exports;
}

function escapeHtml(text) {
  return String(text)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function unwrapStringResult(result) {
  if (api.result_is_ok(result)) {
    return api.result_unwrap(result);
  }
  throw new Error(api.result_error(result));
}

function unwrapSessionResult(result) {
  if (api.session_result_is_ok(result)) {
    return api.session_result_unwrap(result);
  }
  throw new Error(api.session_result_error(result));
}

function renderValidationResult(result) {
  if (api.result_is_ok(result)) {
    const manifestText = api.result_unwrap(result);
    validationNode.textContent = manifestText;
    try {
      currentValidationLookup = buildValidationLookup(manifestText);
    } catch {
      currentValidationLookup = null;
    }
    return;
  }
  validationNode.textContent = api.result_error(result);
  currentValidationLookup = null;
}

// The validation manifest is the schema-side metadata channel into the browser
// host. Normalize it once so action rendering can look up field/transition
// details without re-walking raw JSON every time.
function buildValidationLookup(manifestText) {
  const manifest = JSON.parse(manifestText);
  const entities = new Map();
  for (const entity of manifest.entities ?? []) {
    const fieldLookup = new Map(
      (entity.fields ?? []).map((field) => [field.name, field]),
    );
    const transitionLookup = new Map(
      (entity.transitions ?? []).map((transition) => [
        transition.name,
        {
          ...transition,
          inputLookup: new Map(
            (transition.inputs ?? []).map((input) => [input.name, input]),
          ),
        },
      ]),
    );
    entities.set(entity.name, { fieldLookup, transitionLookup });
  }
  return { entities };
}

function buildReferenceCatalog(catalogText) {
  const catalog = JSON.parse(catalogText);
  const targets = new Map(
    (catalog.targets ?? []).map((target) => [target.name, target.options ?? []]),
  );
  return { targets };
}

function getValidationEntity(snapshot) {
  return currentValidationLookup?.entities.get(snapshot.entityName) ?? null;
}

function getValidationAction(snapshot, action) {
  return getValidationEntity(snapshot)?.transitionLookup.get(action.name) ?? null;
}

function getReferenceOptions(target) {
  return currentReferenceCatalog?.targets.get(target) ?? [];
}

function getValidationInput(snapshot, action, input) {
  const entity = getValidationEntity(snapshot);
  const transitionInput =
    entity?.transitionLookup.get(action.name)?.inputLookup.get(input.name) ?? null;
  const field =
    input.kind === "entity-field" ? entity?.fieldLookup.get(input.name) ?? null : null;
  return { transitionInput, field };
}

function inputKindLabel(kind) {
  return kind === "local" ? t().inputKindLocal : t().inputKindEntityField;
}

function renderChips(chips) {
  if (chips.length === 0) {
    return "";
  }
  return `<div class="action-input-meta">${chips
    .map((chip) => `<span class="chip">${escapeHtml(chip)}</span>`)
    .join("")}</div>`;
}

function renderActionHeaderMeta(snapshot, action) {
  const validationAction = getValidationAction(snapshot, action);
  if (!validationAction?.guard) {
    return "";
  }
  return `<p class="action-meta">${escapeHtml(t().guardLabel)}: ${escapeHtml(
    validationAction.guard,
  )}</p>`;
}

function renderRuntimeValue(value) {
  if (value === null || value === undefined || value === "") {
    return `<span class="view-empty">${escapeHtml(t().emptyValue)}</span>`;
  }
  return escapeHtml(String(value));
}

function renderCurrentViewFieldMeta(snapshot, field) {
  const validationField =
    getValidationEntity(snapshot)?.fieldLookup.get(field.name) ?? null;
  const chips = [field.component, field.mode];
  if (validationField?.type) {
    chips.unshift(validationField.type);
  }
  if (validationField?.target) {
    chips.push(`${t().targetTag}: ${validationField.target}`);
  }
  if (validationField?.system) {
    chips.push(t().systemTag);
  }
  return renderChips(chips);
}

function renderCurrentView(snapshot) {
  if (!snapshot) {
    currentViewNode.innerHTML = `<p>${escapeHtml(t().noCurrentView)}</p>`;
    return;
  }
  const fields = snapshot.fields ?? [];
  const summary = `<div class="view-summary">
      <strong>${escapeHtml(snapshot.entityLabel ?? snapshot.entityName)}</strong>
      <p class="action-meta">${escapeHtml(t().stateMetaLabel)}: ${escapeHtml(
        snapshot.stateLabel ?? snapshot.state,
      )} · ${escapeHtml(t().viewNameMetaLabel)}: ${escapeHtml(
        snapshot.viewName,
      )}</p>
    </div>`;
  if (fields.length === 0) {
    currentViewNode.innerHTML = `${summary}<p>${escapeHtml(t().noCurrentViewFields)}</p>`;
    return;
  }
  currentViewNode.innerHTML = `${summary}<div class="view-field-grid">${fields
    .map(
      (field) => `<article class="view-field-card">
          <h3>${escapeHtml(field.label ?? field.name)}</h3>
          ${renderCurrentViewFieldMeta(snapshot, field)}
          <div class="view-field-value">${renderRuntimeValue(field.value)}</div>
        </article>`,
    )
    .join("")}</div>`;
}

function renderActionInputMeta(snapshot, action, input) {
  const metadata = getValidationInput(snapshot, action, input);
  const transitionInput = metadata.transitionInput;
  const field = metadata.field;
  const chips = [inputKindLabel(input.kind)];
  if (transitionInput?.type) {
    chips.push(transitionInput.type);
  }
  if (transitionInput?.readOnly || field?.readOnly) {
    chips.push(t().readOnlyTag);
  }
  if (field?.system) {
    chips.push(t().systemTag);
  }
  if (transitionInput?.target) {
    chips.push(`${t().targetTag}: ${transitionInput.target}`);
  }
  if (transitionInput && transitionInput.default !== null) {
    chips.push(`${t().defaultTag}: ${transitionInput.default}`);
  }
  return renderChips(chips);
}

function getFailedInputValue(actionName, inputName) {
  const payload = actionFailures.get(actionName)?.payload;
  return payload && Object.prototype.hasOwnProperty.call(payload, inputName)
    ? payload[inputName]
    : undefined;
}

function renderActionFailure(actionName) {
  const failure = actionFailures.get(actionName);
  if (!failure) {
    return "";
  }
  const kindBlock = failure.kind
    ? `<div class="action-meta">${escapeHtml(t().errorKindLabel)}: ${escapeHtml(
        failure.kind,
      )}</div>`
    : "";
  const issuesBlock =
    failure.issues && failure.issues.length > 0
      ? `<div class="action-meta">${escapeHtml(t().issuesLabel)}</div>
         <ul class="action-issues">${failure.issues
           .map(
             (issue) => `<li>${issue.path ? `<code>${escapeHtml(issue.path)}</code>: ` : ""}${escapeHtml(
               issue.message,
             )}</li>`,
           )
           .join("")}</ul>`
      : "";
  const payloadText = JSON.stringify(failure.payload, null, 2);
  return `<div class="action-error">
    <strong>${escapeHtml(t().lastErrorLabel)}</strong>
    ${kindBlock}
    <div>${escapeHtml(failure.message)}</div>
    ${issuesBlock}
    <div class="action-meta">${escapeHtml(t().lastPayloadLabel)}</div>
    <pre class="action-error-payload">${escapeHtml(payloadText)}</pre>
  </div>`;
}

function renderActionInputControl(snapshot, action, input) {
  const inputId = `action-${action.name}-${input.name}`;
  const metadata = getValidationInput(snapshot, action, input);
  const transitionInput = metadata.transitionInput;
  const field = metadata.field;
  const failedValue = getFailedInputValue(action.name, input.name);
  const value =
    failedValue !== undefined
      ? failedValue
      : (input.value ?? transitionInput?.default ?? "");
  const readOnly = transitionInput?.readOnly || field?.readOnly || field?.system;
  const requiredAttr = transitionInput?.required ? " required" : "";
  const readOnlyAttr = readOnly ? " readonly" : "";
  const disabledAttr = field?.system ? " disabled" : "";
  const valueType = transitionInput?.type ?? field?.type ?? input.component;
  if (input.component === "textarea") {
    return `<textarea id="${escapeHtml(inputId)}" data-input-name="${escapeHtml(
      input.name,
    )}" data-component="${escapeHtml(input.component)}" data-value-type="${escapeHtml(valueType)}"${requiredAttr}${readOnlyAttr}${disabledAttr}>${escapeHtml(
      value,
    )}</textarea>`;
  }
  if (input.component === "checkbox") {
    const checked = value === true ? " checked" : "";
    return `<input id="${escapeHtml(inputId)}" type="checkbox" data-input-name="${escapeHtml(
      input.name,
     )}" data-component="${escapeHtml(input.component)}" data-value-type="${escapeHtml(valueType)}"${checked}${disabledAttr}>`;
  }
  if (input.component === "reference-select") {
    const target = transitionInput?.target ?? field?.target ?? "";
    const renderedValue = value === null ? "" : String(value);
    const options = [...getReferenceOptions(target)];
    if (renderedValue !== "" && !options.some((option) => option.value === renderedValue)) {
      options.unshift({ value: renderedValue, label: renderedValue });
    }
    const selectDisabledAttr = readOnly || field?.system ? " disabled" : "";
    return `<select id="${escapeHtml(inputId)}" data-input-name="${escapeHtml(
      input.name,
    )}" data-component="${escapeHtml(input.component)}" data-value-type="${escapeHtml(
      valueType,
    )}"${requiredAttr}${selectDisabledAttr}>
      <option value="">${escapeHtml(t().referencePlaceholder)}</option>
      ${options
        .map((option) => {
          const selected = option.value === renderedValue ? " selected" : "";
          return `<option value="${escapeHtml(option.value)}"${selected}>${escapeHtml(
            option.label,
          )}</option>`;
        })
        .join("")}
    </select>`;
  }
  const fieldType = transitionInput?.type ?? field?.type ?? null;
  const inputType =
    input.component === "number" || input.component === "money"
      ? "number"
      : input.component === "date-picker"
        ? "date"
        : input.component === "datetime-picker"
          ? "datetime-local"
      : "text";
  const stepAttr = fieldType === "money" ? ' step="0.01"' : "";
  const renderedValue = value === null ? "" : String(value);
  return `<input id="${escapeHtml(inputId)}" type="${inputType}" data-input-name="${escapeHtml(
    input.name,
  )}" data-component="${escapeHtml(
    input.component,
  )}" data-value-type="${escapeHtml(valueType)}" value="${escapeHtml(renderedValue)}"${requiredAttr}${readOnlyAttr}${disabledAttr}${stepAttr}>`;
}

function renderActions(snapshot) {
  if (snapshot.actions.length === 0) {
    actionsNode.innerHTML = `<p>${escapeHtml(t().noActions)}</p>`;
    return;
  }
  actionsNode.innerHTML = snapshot.actions
    .map((action) => {
      const inputs = action.inputs
        .map(
          (input) => `
            <label>
              <span>${escapeHtml(input.label ?? input.name)}${
                input.required ? " *" : ""
              }</span>
              ${renderActionInputMeta(snapshot, action, input)}
              ${renderActionInputControl(snapshot, action, input)}
            </label>`,
        )
        .join("");
      const issues =
        action.issues.length === 0
          ? ""
          : `<ul class="action-issues">${action.issues
              .map((issue) => `<li>${escapeHtml(issue)}</li>`)
              .join("")}</ul>`;
      const disabled = action.available ? "" : " disabled";
      return `
        <section class="action-card" data-action-name="${escapeHtml(action.name)}">
          <h3>${escapeHtml(action.name)} → ${escapeHtml(action.to)}</h3>
          ${renderActionHeaderMeta(snapshot, action)}
          ${issues}
          ${inputs}
          ${renderActionFailure(action.name)}
          <button type="button" data-action-apply="${escapeHtml(action.name)}"${disabled}>${escapeHtml(
            t().applyAction,
          )}</button>
        </section>`;
    })
    .join("");
}

function collectActionInputJson(actionCard) {
  const payload = {};
  for (const field of actionCard.querySelectorAll("[data-input-name]")) {
    const name = field.dataset.inputName;
    const valueType = field.dataset.valueType ?? field.dataset.component;
    if (field.type === "checkbox") {
      payload[name] = field.checked;
    } else if (valueType === "number") {
      payload[name] = field.value === "" ? null : Number.parseInt(field.value, 10);
    } else if (valueType === "money") {
      payload[name] = field.value === "" ? null : Number.parseFloat(field.value);
    } else {
      payload[name] = field.value;
    }
  }
  return JSON.stringify(payload);
}

async function renderSession() {
  if (!api) {
    statusNode.textContent = t().wasmNotLoaded;
    return;
  }
  actionFailures.clear();
  currentSnapshot = null;
  currentSession = unwrapSessionResult(
    api.create_demo_session(yamlNode.value, actorRoleNode.value),
  );
  await refreshSessionUi();
}

async function refreshSessionUi() {
  const localizedHtml = unwrapStringResult(
    api.session_preview_html(currentSession, currentLocale),
  );
  previewNode.srcdoc = localizedHtml;
  currentSnapshot = JSON.parse(
    unwrapStringResult(api.session_snapshot_json(currentSession, currentLocale)),
  );
  renderValidationResult(api.render_validation_manifest(yamlNode.value));
  currentReferenceCatalog = buildReferenceCatalog(
    unwrapStringResult(api.session_reference_catalog_json(currentSession, currentLocale)),
  );
  renderCurrentView(currentSnapshot);
  renderActions(currentSnapshot);
  statusNode.textContent = t().sessionReady(
    currentSnapshot.stateLabel ?? currentSnapshot.state,
  );
}

async function handleApplyTransition(transitionName, actionCard) {
  const payloadText = collectActionInputJson(actionCard);
  try {
    const result = api.apply_session_transition(
      currentSession,
      transitionName,
      payloadText,
    );
    if (!api.session_result_is_ok(result)) {
      const failure = JSON.parse(api.session_result_error_json(result));
      actionFailures.set(transitionName, {
        kind: failure.kind ?? "error",
        message: failure.message ?? api.session_result_error(result),
        issues: Array.isArray(failure.issues) ? failure.issues : [],
        payload: JSON.parse(payloadText),
      });
      if (currentSnapshot) {
        renderCurrentView(currentSnapshot);
        renderActions(currentSnapshot);
      }
      statusNode.textContent = failure.message ?? api.session_result_error(result);
      return;
    }
    currentSession = api.session_result_unwrap(result);
    actionFailures.clear();
    await refreshSessionUi();
    statusNode.textContent = t().transitionApplied(transitionName);
  } catch (err) {
    actionFailures.set(transitionName, {
      message: String(err),
      payload: JSON.parse(payloadText),
    });
    if (currentSnapshot) {
      renderCurrentView(currentSnapshot);
      renderActions(currentSnapshot);
    }
    statusNode.textContent = String(err);
  }
}

async function main() {
  applyLocale();
  statusNode.textContent = t().fetching;
  [exampleYamlText, api] = await Promise.all([
    fetch(yamlUrl).then((res) => res.text()),
    loadWasm(),
  ]);
  yamlNode.value = exampleYamlText;
  localeNode.addEventListener("change", () => {
    currentLocale = localeNode.value;
    applyLocale();
    if (!api) {
      statusNode.textContent = t().loading;
      return;
    }
    if (currentSession) {
      refreshSessionUi().catch((err) => {
        statusNode.textContent = String(err);
      });
    }
  });
  actorRoleNode.addEventListener("change", () => {
    renderSession().catch((err) => {
      statusNode.textContent = String(err);
    });
  });
  renderButton.addEventListener("click", () => {
    renderSession().catch((err) => {
      statusNode.textContent = String(err);
    });
  });
  resetButton.addEventListener("click", () => {
    yamlNode.value = exampleYamlText;
    actorRoleNode.value = "";
    renderSession().catch((err) => {
      statusNode.textContent = String(err);
    });
  });
  actionsNode.addEventListener("click", (event) => {
    const button = event.target.closest("[data-action-apply]");
    if (!button) {
      return;
    }
    const actionCard = button.closest("[data-action-name]");
    if (!actionCard) {
      return;
    }
    handleApplyTransition(button.dataset.actionApply, actionCard).catch((err) => {
      statusNode.textContent = String(err);
    });
  });
  await renderSession();
}

main().catch((err) => {
  statusNode.textContent = String(err);
});
