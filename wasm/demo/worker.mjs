let editorModulePromise;

export default {
  async fetch(request, env) {
    return handleRequest(request, env);
  },
};

export async function handleRequest(request, env) {
  const url = new URL(request.url);
  const editorModule = url.pathname.startsWith("/api/editor/") ? await loadEditorModule() : null;

  if (request.method === "POST" && url.pathname === "/api/editor/compile") {
    const body = await readJsonBody(request);
    return jsonText(editorModule.editor_compile_json(body.source ?? "", body.locale ?? ""));
  }

  if (request.method === "POST" && url.pathname === "/api/editor/runtime-preview") {
    const body = await readJsonBody(request);
    return jsonText(
      editorModule.editor_runtime_preview_json(
        body.source ?? "",
        body.actorRole ?? "",
        serializeMaybeJson(body.record),
        body.locale ?? "",
      ),
    );
  }

  if (request.method === "POST" && url.pathname === "/api/editor/apply-transition") {
    const body = await readJsonBody(request);
    return jsonText(
      editorModule.editor_apply_transition_json(
        body.source ?? "",
        body.transitionName ?? "",
        serializeMaybeJson(body.input),
        body.actorRole ?? "",
        serializeMaybeJson(body.record),
        body.locale ?? "",
      ),
    );
  }

  if (url.pathname.startsWith("/api/editor/")) {
    return new Response(JSON.stringify({ ok: false, error: { kind: "not-found", message: "unknown editor route" } }), {
      status: 404,
      headers: { "content-type": "application/json; charset=utf-8" },
    });
  }

  return env.ASSETS.fetch(request);
}

async function loadEditorModule() {
  editorModulePromise ??= import("../../_build/js/release/build/wasm/demo/demo.js");
  return editorModulePromise;
}

async function readJsonBody(request) {
  try {
    return await request.json();
  } catch {
    return {};
  }
}

function serializeMaybeJson(value) {
  if (typeof value === "string") return value;
  if (value == null) return "";
  return JSON.stringify(value);
}

function jsonText(payload) {
  return new Response(payload, {
    status: 200,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
    },
  });
}
