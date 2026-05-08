export function createInitialState() {
  return {
    source: "",
    emittedYaml: "",
    actorRole: "",
    diagnostics: [],
    entities: [],
    selectedEntityName: "",
    selection: { kind: "field", name: "" },
    model: null,
    runtimeRecord: null,
    previewHtml: "",
    runtimeView: null,
  };
}

export function readNormalizedPayload(compileResult) {
  return compileResult?.normalizedSchema?.payload ?? null;
}

export function preferredEntityName(model) {
  for (const entity of model?.entities ?? []) {
    if ((entity.states?.length ?? 0) > 0 || (entity.transitions?.length ?? 0) > 0) {
      return entity.name;
    }
  }
  return model?.entities?.[0]?.name ?? "";
}

export function ensureSelection(state) {
  const entity = findSelectedEntity(state);
  if (!entity) {
    state.selection = { kind: "field", name: "" };
    return;
  }

  if (!state.selection?.name) {
    state.selection = {
      kind: entity.fields[0] ? "field" : entity.states[0] ? "state" : entity.transitions[0] ? "transition" : "view",
      name:
        entity.fields[0]?.name ??
        entity.states[0]?.name ??
        entity.transitions[0]?.name ??
        entity.views[0]?.name ??
        "",
    };
    return;
  }

  const pool = selectionPool(entity, state.selection.kind);
  if (!pool.some((item) => item.name === state.selection.name)) {
    state.selection = {
      kind: "field",
      name: entity.fields[0]?.name ?? "",
    };
  }
}

export function findSelectedEntity(state) {
  return state.model?.entities?.find((entity) => entity.name === state.selectedEntityName) ?? null;
}

export function selectionPool(entity, kind) {
  switch (kind) {
    case "field":
      return entity.fields ?? [];
    case "state":
      return entity.states ?? [];
    case "transition":
      return entity.transitions ?? [];
    case "view":
      return entity.views ?? [];
    default:
      return [];
  }
}

export function updateSelectedEntity(state, entityName) {
  state.selectedEntityName = entityName;
  ensureSelection(state);
}

export function updateSelection(state, kind, name) {
  state.selection = { kind, name };
}

export function selectedNode(state) {
  const entity = findSelectedEntity(state);
  if (!entity) return null;
  return selectionPool(entity, state.selection.kind).find((item) => item.name === state.selection.name) ?? null;
}

export function cloneModel(model) {
  return structuredClone(model);
}

export function createFieldDraft(entity) {
  const nextName = uniqueName(entity.fields, "newField");
  return {
    name: nextName,
    type: "text",
    label: nextName,
    labels: {},
    required: false,
    readOnly: false,
    system: false,
    primary: false,
    column: nextName,
    default: null,
    target: null,
    initial: null,
  };
}

export function createStateDraft(entity) {
  const nextName = uniqueName(entity.states, "newState");
  return {
    name: nextName,
    label: nextName,
    labels: {},
  };
}

export function createTransitionDraft(entity) {
  const nextName = uniqueName(entity.transitions, "newTransition");
  const firstState = entity.states[0]?.name ?? "draft";
  return {
    name: nextName,
    from: firstState,
    to: firstState,
    guard: null,
    role: null,
    inputs: [],
  };
}

export function createViewDraft(entity) {
  const fallback = entity.states[0]?.name ?? uniqueName(entity.views, "newView");
  return {
    name: uniqueName(entity.views, fallback),
    editableFields: [],
    readonlyFields: [],
  };
}

function uniqueName(items, base) {
  const names = new Set(items.map((item) => item.name));
  if (!names.has(base)) return base;
  let index = 2;
  while (names.has(`${base}${index}`)) index += 1;
  return `${base}${index}`;
}

export function emitSchemaYaml(model) {
  const lines = ["entities:"];
  for (const entity of model.entities ?? []) {
    lines.push(`  ${yamlKey(entity.name)}:`);
    pushLocalized(lines, "    ", "label", entity.label, entity.labels);
    if (entity.fields?.length) {
      lines.push("    fields:");
      for (const field of entity.fields) {
        lines.push(`      ${yamlKey(field.name)}:`);
        pushLocalized(lines, "        ", "label", field.label ?? field.name, field.labels);
        lines.push(`        type: ${yamlScalar(field.type)}`);
        if (field.required) lines.push("        required: true");
        if (field.primary) lines.push("        primary: true");
        if (field.readOnly) lines.push("        read_only: true");
        if (field.system) lines.push("        system: true");
        if (field.default != null && field.default !== "") lines.push(`        default: ${yamlScalar(field.default)}`);
        if (field.target) lines.push(`        target: ${yamlScalar(field.target)}`);
        if (field.initial) lines.push(`        initial: ${yamlScalar(field.initial)}`);
      }
    }
    if (entity.relations?.length) {
      lines.push("    relations:");
      for (const relation of entity.relations) {
        lines.push(`      ${yamlKey(relation.name)}:`);
        lines.push(`        kind: ${yamlScalar(yamlRelationKind(relation.kind))}`);
        lines.push(`        target: ${yamlScalar(relation.target)}`);
        lines.push(`        field: ${yamlScalar(relation.field)}`);
      }
    }
    if (entity.constraints?.length) {
      lines.push("    constraints:");
      for (const constraint of entity.constraints) {
        lines.push(`      ${yamlKey(constraint.name)}:`);
        lines.push(`        expr: ${yamlScalar(constraint.expr)}`);
      }
    }
    if (entity.states?.length) {
      lines.push("    states:");
      for (const state of entity.states) {
        lines.push(`      ${yamlKey(state.name)}:`);
        pushLocalized(lines, "        ", "label", state.label ?? state.name, state.labels);
      }
    }
    if (entity.transitions?.length) {
      lines.push("    transitions:");
      for (const transition of entity.transitions) {
        lines.push(`      ${yamlKey(transition.name)}:`);
        lines.push(`        from: ${yamlScalar(transition.from)}`);
        lines.push(`        to: ${yamlScalar(transition.to)}`);
        if (transition.role) lines.push(`        role: ${yamlScalar(transition.role)}`);
        if (transition.inputs?.length) {
          lines.push("        input:");
          for (const input of transition.inputs) lines.push(`          - ${yamlScalar(input.name)}`);
          const locals = transition.inputs.filter((input) => input.kind === "local");
          if (locals.length) {
            lines.push("        inputs:");
            for (const input of locals) {
              lines.push(`          ${yamlKey(input.name)}:`);
              lines.push(`            type: ${yamlScalar(input.type)}`);
              if (input.required) lines.push("            required: true");
              if (input.readOnly) lines.push("            read_only: true");
              if (input.default != null && input.default !== "") lines.push(`            default: ${yamlScalar(input.default)}`);
              if (input.target) lines.push(`            target: ${yamlScalar(input.target)}`);
            }
          }
        }
        if (transition.guard) lines.push(`        guard: ${yamlScalar(transition.guard)}`);
      }
    }
    if (entity.rules?.length) {
      lines.push("    rules:");
      for (const rule of entity.rules) {
        lines.push(`      ${yamlKey(rule.name)}:`);
        lines.push(`        when: ${yamlScalar(rule.when)}`);
      }
    }
    if (entity.views?.length) {
      lines.push("    views:");
      for (const view of entity.views) {
        lines.push(`      ${yamlKey(view.name)}:`);
        if (view.editableFields?.length) {
          lines.push("        editable:");
          for (const fieldName of view.editableFields) lines.push(`          - ${yamlScalar(fieldName)}`);
        }
        if (view.readonlyFields?.length) {
          lines.push("        readonly:");
          for (const fieldName of view.readonlyFields) lines.push(`          - ${yamlScalar(fieldName)}`);
        }
      }
    }
    const storage = entity.storage ?? {};
    const defaultTable = pluralizeSnake(entity.name);
    if (
      storage.table !== defaultTable ||
      storage.softDelete ||
      (storage.indexes?.length ?? 0) > 0 ||
      (storage.unique?.length ?? 0) > 0
    ) {
      lines.push("    storage:");
      if (storage.table && storage.table !== defaultTable) {
        lines.push(`      table: ${yamlScalar(storage.table)}`);
      }
      if (storage.indexes?.length) {
        lines.push("      indexes:");
        for (const index of storage.indexes) {
          lines.push(`        - fields: ${yamlInlineList(index.fields ?? [])}`);
        }
      }
      if (storage.unique?.length) {
        lines.push("      unique:");
        for (const uniqueKey of storage.unique) {
          lines.push(`        - fields: ${yamlInlineList(uniqueKey.fields ?? [])}`);
        }
      }
      if (storage.softDelete) {
        lines.push("      softDelete: true");
      }
    }
  }
  return `${lines.join("\n")}\n`;
}

function pushLocalized(lines, indent, key, fallback, labels) {
  const labelEntries = Object.entries(labels ?? {}).filter(([, value]) => value != null && value !== "");
  if (labelEntries.length === 0) {
    lines.push(`${indent}${key}: ${yamlScalar(fallback)}`);
    return;
  }
  if (labelEntries.length === 1 && labelEntries[0][0] === "default") {
    lines.push(`${indent}${key}: ${yamlScalar(labelEntries[0][1])}`);
    return;
  }
  lines.push(`${indent}${key}:`);
  for (const [lang, value] of labelEntries.sort(([left], [right]) => left.localeCompare(right))) {
    lines.push(`${indent}  ${yamlKey(lang)}: ${yamlScalar(value)}`);
  }
}

function yamlRelationKind(kind) {
  switch (kind) {
    case "1:1":
      return "one_to_one";
    case "1:N":
      return "one_to_many";
    case "N:1":
      return "many_to_one";
    case "N:N":
      return "many_to_many";
    default:
      return kind;
  }
}

function pluralizeSnake(name) {
  return `${name
    .replaceAll(/([a-z0-9])([A-Z])/g, "$1_$2")
    .replaceAll(/[-\s]+/g, "_")
    .toLowerCase()}s`;
}

function yamlKey(value) {
  return yamlScalar(value);
}

function yamlInlineList(values) {
  return `[${values.map((value) => yamlScalar(value)).join(", ")}]`;
}

function yamlScalar(value) {
  const text = String(value ?? "");
  return `"${text
    .replaceAll("\\", "\\\\")
    .replaceAll('"', '\\"')
    .replaceAll("\n", "\\n")
    .replaceAll("\r", "\\r")
    .replaceAll("\t", "\\t")
    .replaceAll("\b", "\\b")
    .replaceAll("\f", "\\f")
    .replaceAll(/[\u0000-\u001f]/g, (char) => `\\u${char.charCodeAt(0).toString(16).padStart(4, "0")}`)}"`;
}
