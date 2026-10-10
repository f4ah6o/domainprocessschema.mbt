import { bindings, defineConfig } from "cf/config";

/**
 * Secret-like files were detected but not read or migrated: wasm/demo/.env.opz.example. Only `secrets.required` entries are migrated.
 * @see https://developers.cloudflare.com/workers/configuration/secrets/
 */

/**
 * Wrangler environments are selected through ctx.mode and the cf --mode flag.
 * @see https://developers.cloudflare.com/workers/wrangler/environments/
 */

export default defineConfig((ctx) => {
	switch (ctx.mode) {
		case "preview": {
			return {
				worker: {
					name: "domainprocessschema-wasm-demo-preview",
					compatibilityDate: "2026-05-05",
					entrypoint: "./wasm/demo/worker.mjs",
					assets: {
						htmlHandling: "auto-trailing-slash",
						notFoundHandling: "404-page",
					},
					env: {
						ASSETS: bindings.assets(),
					},
				},
			};
		}
		default: {
			return {
				worker: {
					name: "domainprocessschema-wasm-demo",
					compatibilityDate: "2026-05-05",
					entrypoint: "./wasm/demo/worker.mjs",
					assets: {
						htmlHandling: "auto-trailing-slash",
						notFoundHandling: "404-page",
					},
					env: {
						ASSETS: bindings.assets(),
					},
				},
			};
		}
	}
});
