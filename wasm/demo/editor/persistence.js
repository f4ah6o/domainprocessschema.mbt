const STORAGE_KEY = "domainprocessschema.editor.source";

export function loadPersistedSource() {
  return globalThis.localStorage?.getItem(STORAGE_KEY) ?? "";
}

export function savePersistedSource(source) {
  globalThis.localStorage?.setItem(STORAGE_KEY, source);
}
