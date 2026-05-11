const MAX_REQUEST_BYTES = 64 * 1024;

export default {
  async fetch(request, env) {
    try {
      const url = new URL(request.url);

      if (url.pathname === "/api/health") {
        return json({ ok: true, version: 1 });
      }

      if (url.pathname === "/api/schema/compile") {
        return compileSchemaRequest(request);
      }

      if (url.pathname === "/demo") {
        return Response.redirect(new URL("/demo/", request.url), 308);
      }

      return withAssetHeaders(await env.ASSETS.fetch(request));
    } catch (error) {
      return jsonError(500, "INTERNAL_ERROR", "Unexpected worker error.", {
        detail: String(error?.message ?? error),
      });
    }
  },
};

async function compileSchemaRequest(request) {
  if (request.method !== "POST") {
    return jsonError(405, "METHOD_NOT_ALLOWED", "Use POST for schema compilation.");
  }

  const lengthHeader = request.headers.get("content-length");
  const contentLength = lengthHeader === null ? 0 : Number(lengthHeader);
  if (Number.isFinite(contentLength) && contentLength > MAX_REQUEST_BYTES) {
    return jsonError(413, "REQUEST_TOO_LARGE", "Request body exceeds 64 KiB.", {
      maxBytes: MAX_REQUEST_BYTES,
    });
  }

  const body = await readLimitedText(request, MAX_REQUEST_BYTES);
  if (!body.ok) {
    return jsonError(413, "REQUEST_TOO_LARGE", "Request body exceeds 64 KiB.", {
      maxBytes: MAX_REQUEST_BYTES,
    });
  }

  let payload;
  try {
    payload = JSON.parse(body.text);
  } catch {
    return jsonError(400, "BAD_JSON", "Request body must be JSON.");
  }

  if (typeof payload.sourceYaml !== "string") {
    return jsonError(400, "BAD_SCHEMA_SOURCE", "`sourceYaml` must be a string.");
  }

  return json({
    ok: true,
    sourceBytes: new TextEncoder().encode(payload.sourceYaml).byteLength,
    artifacts: [
      "source-yaml",
      "normalized-schema",
      "api-manifest",
      "validation-manifest",
      "gui-manifest",
      "runtime-session",
      "diagnostic-report",
    ],
    note:
      "Browser-side MoonBit WASM compiles the schema. The Worker API currently provides request validation for production integration.",
  });
}

async function readLimitedText(request, maxBytes) {
  const reader = request.body?.getReader();
  if (!reader) {
    return { ok: true, text: "" };
  }
  const chunks = [];
  let size = 0;
  while (true) {
    const { done, value } = await reader.read();
    if (done) {
      break;
    }
    size += value.byteLength;
    if (size > maxBytes) {
      await reader.cancel("request body exceeded size limit");
      return { ok: false, text: "" };
    }
    chunks.push(value);
  }
  const bytes = new Uint8Array(size);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return { ok: true, text: new TextDecoder().decode(bytes) };
}

function json(value, init = {}) {
  return new Response(JSON.stringify(value, null, 2), {
    ...init,
    headers: {
      "content-type": "application/json; charset=utf-8",
      ...init.headers,
    },
  });
}

function withAssetHeaders(response) {
  const headers = new Headers(response.headers);
  headers.set("x-content-type-options", "nosniff");
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

function jsonError(status, code, message, details = {}) {
  return json(
    {
      ok: false,
      error: {
        code,
        message,
        details,
      },
    },
    { status },
  );
}

export { MAX_REQUEST_BYTES, readLimitedText };
