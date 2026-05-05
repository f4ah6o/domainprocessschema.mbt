import { copyFileSync, existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const rootDir = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const outDir = resolve(rootDir, "_build/cloudflare/wasm-demo");
const wasmSource = resolve(rootDir, "_build/wasm-gc/release/build/wasm/demo/demo.wasm");
const indexSource = resolve(rootDir, "wasm/demo/index.html");
const mainJsSource = resolve(rootDir, "wasm/demo/main.js");
const yamlSource = resolve(rootDir, "examples/expense_request.yaml");

for (const file of [wasmSource, indexSource, mainJsSource, yamlSource]) {
  if (!existsSync(file)) {
    throw new Error(`Missing required build input: ${file}`);
  }
}

rmSync(outDir, { recursive: true, force: true });
mkdirSync(resolve(outDir, "examples"), { recursive: true });

copyFileSync(indexSource, resolve(outDir, "index.html"));
copyFileSync(wasmSource, resolve(outDir, "demo.wasm"));
copyFileSync(yamlSource, resolve(outDir, "examples/expense_request.yaml"));

let mainJs = readFileSync(mainJsSource, "utf8");
mainJs = replaceExact(
  mainJs,
  'const wasmUrl = "../../_build/wasm-gc/release/build/wasm/demo/demo.wasm";',
  'const wasmUrl = "./demo.wasm";',
);
mainJs = replaceExact(
  mainJs,
  'const yamlUrl = "../../examples/expense_request.yaml";',
  'const yamlUrl = "./examples/expense_request.yaml";',
);
writeFileSync(resolve(outDir, "main.js"), mainJs);

function replaceExact(source, search, replacement) {
  if (!source.includes(search)) {
    throw new Error(`Expected source snippet not found: ${search}`);
  }
  return source.replace(search, replacement);
}
