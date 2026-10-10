import { defineWranglerConfig } from "wrangler/experimental-config";

export default defineWranglerConfig((ctx) => {
	switch (ctx.mode) {
		case "preview": {
			return {
				assetsDirectory: "./_build/cloudflare/wasm-demo",
			};
		}
		default: {
			return {
				assetsDirectory: "./_build/cloudflare/wasm-demo",
			};
		}
	}
});
