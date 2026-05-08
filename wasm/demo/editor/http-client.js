export async function postEditorJson(path, body) {
  const response = await fetch(`/api/editor/${path}`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!response.ok) {
    throw new Error(`${path} failed: ${response.status}`);
  }
  return await response.json();
}
