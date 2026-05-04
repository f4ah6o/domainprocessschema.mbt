import { defineConfig } from "vite";
import { createReadStream } from "node:fs";
import path from "node:path";

const repoRoot = path.resolve(import.meta.dirname, "..", "..");
const wasmPath = path.join(
  repoRoot,
  "_build",
  "wasm-gc",
  "release",
  "build",
  "wasm",
  "demo",
  "demo.wasm",
);
const yamlPath = path.join(repoRoot, "examples", "expense_request.yaml");

export default defineConfig({
  root: import.meta.dirname,
  server: {
    port: 3000,
    open: true,
    fs: {
      allow: [repoRoot],
    },
  },
  publicDir: false,
  configureServer(server) {
    server.middlewares.use((req, res, next) => {
      if (req.url === "/demo.wasm") {
        res.setHeader("Content-Type", "application/wasm");
        res.setHeader("Cache-Control", "no-cache");
        createReadStream(wasmPath).pipe(res);
        return;
      }
      if (req.url === "/expense_request.yaml") {
        res.setHeader("Content-Type", "text/yaml; charset=utf-8");
        res.setHeader("Cache-Control", "no-cache");
        createReadStream(yamlPath).pipe(res);
        return;
      }
      next();
    });
  },
});
