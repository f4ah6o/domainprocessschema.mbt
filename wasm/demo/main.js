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
const actionsHeadingNode = document.getElementById("actions-heading");
const actionsNode = document.getElementById("actions");

let api = null;
let exampleYamlText = "";
let currentLocale = "en";
let currentSession = null;

const translations = {
  en: {
    pageTitle: "domainprocessschema.mbt MoonBit WASM demo",
    pageDescription:
      'This page loads the MoonBit WASM build, fetches <code>examples/expense_request.yaml</code>, and lets you execute transitions from a live runtime session in the browser host.',
    yamlLabel: "YAML source",
    actorRoleLabel: "Actor role",
    localeLabel: "Language",
    renderButton: "Start runtime session",
    resetButton: "Reset example",
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
    renderButton: "runtime session を開始",
    resetButton: "example を戻す",
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
  renderButton.textContent = text.renderButton;
  resetButton.textContent = text.resetButton;
  actionsHeadingNode.textContent = text.actionsHeading;
  validationSummaryNode.textContent = text.validationSummary;
  previewNode.title = text.previewTitle;
  validationNode.textContent = text.validationLoading;
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
  validationNode.textContent = api.result_is_ok(result)
    ? api.result_unwrap(result)
    : api.result_error(result);
}

function renderActionInputControl(actionName, input) {
  const inputId = `action-${actionName}-${input.name}`;
  const value = input.value ?? "";
  if (input.component === "textarea") {
    return `<textarea id="${escapeHtml(inputId)}" data-input-name="${escapeHtml(
      input.name,
    )}" data-component="${escapeHtml(input.component)}">${escapeHtml(
      value,
    )}</textarea>`;
  }
  if (input.component === "checkbox") {
    const checked = value === true ? " checked" : "";
    return `<input id="${escapeHtml(inputId)}" type="checkbox" data-input-name="${escapeHtml(
      input.name,
    )}" data-component="${escapeHtml(input.component)}"${checked}>`;
  }
  const inputType =
    input.component === "number" || input.component === "money"
      ? "number"
      : "text";
  const renderedValue = value === null ? "" : String(value);
  return `<input id="${escapeHtml(inputId)}" type="${inputType}" data-input-name="${escapeHtml(
    input.name,
  )}" data-component="${escapeHtml(
    input.component,
  )}" value="${escapeHtml(renderedValue)}">`;
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
              <span>${escapeHtml(input.name)}${
                input.required ? " *" : ""
              }</span>
              ${renderActionInputControl(action.name, input)}
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
          ${issues}
          ${inputs}
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
    const component = field.dataset.component;
    if (field.type === "checkbox") {
      payload[name] = field.checked;
    } else if (component === "number" || component === "money") {
      payload[name] = field.value === "" ? null : Number.parseInt(field.value, 10);
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
  currentSession = unwrapSessionResult(
    api.create_demo_session(yamlNode.value, actorRoleNode.value),
  );
  await refreshSessionUi();
}

async function refreshSessionUi() {
  const html = unwrapStringResult(api.session_preview_html(currentSession));
  previewNode.srcdoc = html;
  const snapshot = JSON.parse(
    unwrapStringResult(api.session_snapshot_json(currentSession)),
  );
  renderActions(snapshot);
  renderValidationResult(api.render_validation_manifest(yamlNode.value));
  statusNode.textContent = t().sessionReady(snapshot.state);
}

async function handleApplyTransition(transitionName, actionCard) {
  try {
    const result = api.apply_session_transition(
      currentSession,
      transitionName,
      collectActionInputJson(actionCard),
    );
    currentSession = unwrapSessionResult(result);
    await refreshSessionUi();
    statusNode.textContent = t().transitionApplied(transitionName);
  } catch (err) {
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
