import { cp, mkdir, rm } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const dist = join(root, "dist", "cloudflare-demo");
const wasm = join(root, "_build", "wasm-gc", "release", "build", "wasm", "demo", "demo.wasm");

run("moon", ["build", "wasm/demo", "--target", "wasm-gc", "--release"]);

await rm(dist, { recursive: true, force: true });
await mkdir(join(dist, "editor"), { recursive: true });
await mkdir(join(dist, "demo"), { recursive: true });
await mkdir(join(dist, "examples"), { recursive: true });

await cp(join(root, "wasm", "demo", "index.html"), join(dist, "index.html"));
await cp(join(root, "wasm", "demo", "main.js"), join(dist, "main.js"));
await cp(join(root, "wasm", "demo", "runtime-demo.html"), join(dist, "demo", "index.html"));
await cp(join(root, "wasm", "demo", "runtime-demo.js"), join(dist, "demo", "runtime-demo.js"));
await cp(join(root, "wasm", "demo", "editor", "app.css"), join(dist, "editor", "app.css"));
await cp(join(root, "examples", "expense_request.yaml"), join(dist, "examples", "expense_request.yaml"));
await cp(wasm, join(dist, "demo.wasm"));

function run(command, args) {
  const result = spawnSync(command, args, {
    cwd: root,
    stdio: "inherit",
  });
  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}
