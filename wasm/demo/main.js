const wasmUrl = "./demo.wasm";
const yamlUrl = "./examples/expense_request.yaml";

const sourceNode = document.getElementById("yaml-source");
const scenarioNode = document.getElementById("preview-scenario");
const statusNode = document.getElementById("status");
const frameNode = document.getElementById("preview-frame");
const artifactNode = document.getElementById("artifact-output");
const compileButton = document.getElementById("compile-source");
const resetButton = document.getElementById("reset-source");
const formatButton = document.getElementById("format-source");
const downloadButton = document.getElementById("download-artifact");
const tabNodes = [...document.querySelectorAll("[data-artifact]")];

const artifactLabels = {
  sourceYaml: "Source YAML",
  normalizedSchema: "Normalized schema",
  apiManifest: "API manifest",
  validationManifest: "Validation manifest",
  guiManifest: "GUI manifest",
  runtimeSnapshot: "Runtime snapshot",
  diagnostics: "Diagnostics",
};

let api;
let exampleYaml = "";
let activeArtifact = "sourceYaml";
let artifactState = {};

async function loadWasm() {
  const { instance } = await WebAssembly.instantiateStreaming(fetch(wasmUrl), {}, {
    builtins: ["js-string"],
    importedStringConstants: "_",
  });
  return instance.exports;
}

function unwrap(result) {
  if (api.result_is_ok(result)) {
    return { ok: true, value: api.result_unwrap(result) };
  }
  return { ok: false, value: api.result_error(result) };
}

function prettyJson(text) {
  try {
    return JSON.stringify(JSON.parse(text), null, 2);
  } catch {
    return text;
  }
}

function artifactPayload(format) {
  const result = unwrap(api.render_artifact(sourceNode.value, format));
  if (!result.ok) {
    return result.value;
  }
  try {
    return JSON.parse(JSON.parse(result.value).payload);
  } catch {
    return result.value;
  }
}

function compileArtifacts() {
  const yaml = sourceNode.value;
  artifactState = {
    sourceYaml: yaml,
    normalizedSchema: artifactPayload("normalized-schema"),
    apiManifest: unwrap(api.render_api_manifest(yaml)).value,
    validationManifest: unwrap(api.render_validation_manifest(yaml)).value,
    guiManifest: unwrap(api.render_gui_manifest(yaml)).value,
    runtimeSnapshot: unwrap(api.render_runtime_snapshot(yaml)).value,
    diagnostics: unwrap(api.render_diagnostics(yaml)).value,
  };
}

function renderArtifact() {
  const value = artifactState[activeArtifact] ?? "";
  artifactNode.textContent =
    typeof value === "string" ? prettyJson(value) : JSON.stringify(value, null, 2);
}

function renderPreview() {
  const yaml = sourceNode.value;
  const scenario = scenarioNode.value;
  const result = unwrap(
    scenario === "manifest"
      ? api.render_manifest_preview(yaml)
      : api.render_runtime_preview(yaml, scenario),
  );
  if (result.ok) {
    frameNode.srcdoc = result.value;
    statusNode.textContent = `Compiled ${artifactLabels[activeArtifact]}`;
  } else {
    frameNode.srcdoc = "";
    statusNode.textContent = result.value;
  }
}

function compile() {
  compileArtifacts();
  renderArtifact();
  renderPreview();
}

function setActiveArtifact(name) {
  activeArtifact = name;
  for (const tab of tabNodes) {
    tab.classList.toggle("active", tab.dataset.artifact === name);
  }
  renderArtifact();
}

function normalizeSource() {
  sourceNode.value = sourceNode.value.trimEnd() + "\n";
  compile();
}

function downloadArtifact() {
  const value = artifactState[activeArtifact] ?? "";
  const blob = new Blob([typeof value === "string" ? value : JSON.stringify(value, null, 2)], {
    type: activeArtifact === "sourceYaml" ? "application/x-yaml" : "application/json",
  });
  const link = document.createElement("a");
  link.href = URL.createObjectURL(blob);
  link.download = activeArtifact === "sourceYaml" ? "source.yaml" : `${activeArtifact}.json`;
  link.click();
  URL.revokeObjectURL(link.href);
}

async function main() {
  [api, exampleYaml] = await Promise.all([
    loadWasm(),
    fetch(yamlUrl).then((res) => res.text()),
  ]);
  sourceNode.value = exampleYaml;
  compileButton.addEventListener("click", compile);
  scenarioNode.addEventListener("change", renderPreview);
  resetButton.addEventListener("click", () => {
    sourceNode.value = exampleYaml;
    compile();
  });
  formatButton.addEventListener("click", normalizeSource);
  downloadButton.addEventListener("click", downloadArtifact);
  for (const tab of tabNodes) {
    tab.addEventListener("click", () => setActiveArtifact(tab.dataset.artifact));
  }
  compile();
}

main().catch((err) => {
  statusNode.textContent = String(err);
});
