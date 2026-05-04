const wasmUrl = "../../_build/wasm-gc/release/build/wasm/demo/demo.wasm";
const yamlUrl = "../../examples/expense_request.yaml";

const statusNode = document.getElementById("status");
const validationNode = document.getElementById("validation");
const previewNode = document.getElementById("preview");
const scenarioNode = document.getElementById("scenario");
const yamlNode = document.getElementById("yaml");
const localeNode = document.getElementById("locale");
const renderButton = document.getElementById("render");
const resetButton = document.getElementById("reset");
const pageTitleNode = document.getElementById("page-title");
const pageDescriptionNode = document.getElementById("page-description");
const yamlLabelNode = document.getElementById("yaml-label");
const scenarioLabelNode = document.getElementById("scenario-label");
const localeLabelNode = document.getElementById("locale-label");
const validationSummaryNode = document.getElementById("validation-summary");

let api = null;
let exampleYamlText = "";
let currentLocale = "en";

const translations = {
  en: {
    pageTitle: "domainprocessschema.mbt MoonBit WASM demo",
    pageDescription:
      'This page loads the MoonBit WASM build, fetches <code>examples/expense_request.yaml</code>, and renders either the static manifest preview or runtime scenarios into the iframe below.',
    yamlLabel: "YAML source",
    scenarioLabel: "Preview mode",
    localeLabel: "Language",
    renderButton: "Render preview",
    resetButton: "Reset example",
    validationSummary: "validation manifest",
    loading: "Loading WASM demo…",
    fetching: "Fetching schema and WASM module…",
    wasmNotLoaded: "WASM module is not loaded yet.",
    rendered: (scenario) => `Rendered scenario: ${scenario}`,
    previewTitle: "MoonBit WASM preview",
    validationLoading: "Loading validation manifest…",
    scenarios: {
      manifest: "manifest",
      draft: "runtime: draft",
      submitted: "runtime: submitted",
      "submitted-manager": "runtime: submitted-manager",
      "approved-manager": "runtime: approved-manager",
      "rejected-manager": "runtime: rejected-manager",
    },
  },
  ja: {
    pageTitle: "domainprocessschema.mbt MoonBit WASM デモ",
    pageDescription:
      '<code>examples/expense_request.yaml</code> を読み込み、MoonBit WASM build を使って static preview または runtime scenario preview を下の iframe に描画します。',
    yamlLabel: "YAML ソース",
    scenarioLabel: "プレビューモード",
    localeLabel: "表示言語",
    renderButton: "プレビューを描画",
    resetButton: "example を戻す",
    validationSummary: "validation manifest",
    loading: "WASM デモを読み込み中…",
    fetching: "schema と WASM module を取得中…",
    wasmNotLoaded: "WASM module がまだ読み込まれていません。",
    rendered: (scenario) => `描画した scenario: ${scenario}`,
    previewTitle: "MoonBit WASM プレビュー",
    validationLoading: "validation manifest を読み込み中…",
    scenarios: {
      manifest: "manifest",
      draft: "runtime: draft",
      submitted: "runtime: submitted",
      "submitted-manager": "runtime: submitted-manager",
      "approved-manager": "runtime: approved-manager",
      "rejected-manager": "runtime: rejected-manager",
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
  scenarioLabelNode.textContent = text.scenarioLabel;
  localeLabelNode.textContent = text.localeLabel;
  renderButton.textContent = text.renderButton;
  resetButton.textContent = text.resetButton;
  validationSummaryNode.textContent = text.validationSummary;
  previewNode.title = text.previewTitle;
  validationNode.textContent = text.validationLoading;
  for (const option of scenarioNode.options) {
    option.textContent = text.scenarios[option.value] ?? option.value;
  }
}

async function loadWasm() {
  const { instance } = await WebAssembly.instantiateStreaming(
    fetch(wasmUrl),
    {},
    {
      builtins: ["js-string"],
      importedStringConstants: "_",
    },
  );
  return instance.exports;
}

function renderResult(result) {
  if (api.result_is_ok(result)) {
    const html = api.result_unwrap(result);
    previewNode.srcdoc = html;
    statusNode.textContent = t().rendered(
      t().scenarios[scenarioNode.value] ?? scenarioNode.value,
    );
  } else {
    const error = api.result_error(result);
    previewNode.srcdoc = "";
    statusNode.textContent = error;
  }
}

function renderValidationResult(result) {
  validationNode.textContent = api.result_is_ok(result)
    ? api.result_unwrap(result)
    : api.result_error(result);
}

async function renderPreview() {
  if (!api) {
    statusNode.textContent = t().wasmNotLoaded;
    return;
  }
  const scenario = scenarioNode.value;
  const yamlText = yamlNode.value;
  const result =
    scenario === "manifest"
      ? api.render_manifest_preview(yamlText)
      : api.render_runtime_preview(yamlText, scenario);
  renderResult(result);
  renderValidationResult(api.render_validation_manifest(yamlText));
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
    if (api) {
      renderPreview().catch((err) => {
        statusNode.textContent = String(err);
      });
    } else {
      statusNode.textContent = t().loading;
    }
  });
  renderButton.addEventListener("click", () => {
    renderPreview().catch((err) => {
      statusNode.textContent = String(err);
    });
  });
  resetButton.addEventListener("click", () => {
    yamlNode.value = exampleYamlText;
    renderPreview().catch((err) => {
      statusNode.textContent = String(err);
    });
  });
  await renderPreview();
}

main().catch((err) => {
  statusNode.textContent = String(err);
});
