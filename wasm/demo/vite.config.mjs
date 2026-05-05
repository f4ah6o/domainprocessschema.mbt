import { defineConfig } from "vite";
import { readFileSync } from "node:fs";
import path from "node:path";

const repoRoot = path.resolve(import.meta.dirname, "..", "..");

const wasmPath = path.join(
  repoRoot,
  "_build", "wasm-gc", "release", "build", "wasm", "demo", "demo.wasm",
);
const yamlPath = path.join(repoRoot, "examples", "expense_request.yaml");

const wasmBuf = readFileSync(wasmPath);
const yamlText = readFileSync(yamlPath, "utf-8");

export default defineConfig({
  root: import.meta.dirname,
  server: {
    port: 3000,
    open: true,
    fs: { allow: [repoRoot] },
    proxy: {},
  },
  publicDir: false,
  assetsInclude: ["**/*.wasm", "**/*.yaml"],
  plugins: [
    {
      name: "serve-wasm-yaml",
      configureServer(server) {
        server.middlewares.use((req, res, next) => {
          const url = req.url?.split("?")[0];
          if (url === "/demo.wasm") {
            res.writeHead(200, {
              "Content-Type": "application/wasm",
              "Cache-Control": "no-cache",
              "Content-Length": wasmBuf.length,
            });
            res.end(wasmBuf);
            return;
          }
          if (url === "/expense_request.yaml") {
            res.writeHead(200, {
              "Content-Type": "text/yaml; charset=utf-8",
              "Cache-Control": "no-cache",
            });
            res.end(yamlText);
            return;
          }
          next();
        });
      },
    },
  ],
});
