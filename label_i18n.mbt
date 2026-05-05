///|
/// Normalize locale keys so YAML label maps and browser locale values compare
/// consistently (`ja_JP`, `ja-jp`, `JA-JP` all become `ja-jp`).
fn normalize_label_locale(locale : String) -> String {
  locale.trim().to_string().replace_all(old="_", new="-").to_lower()
}

///|
fn default_localized_text(
  translations : Map[String, String],
  fallback : String,
) -> String {
  match translations.get("default") {
    Some(text) => text
    None => fallback
  }
}

///|
fn resolve_localized_text(
  default_text : String,
  translations : Map[String, String],
  locale : String,
) -> String {
  let normalized = normalize_label_locale(locale)
  if normalized != "" {
    match translations.get(normalized) {
      Some(text) => return text
      None => ()
    }
    match normalized.split_once("-") {
      Some((language, _)) => {
        let base_locale = language.to_string()
        match translations.get(base_locale) {
          Some(text) => return text
          None => ()
        }
      }
      None => ()
    }
  }
  match translations.get("default") {
    Some(text) => text
    None => default_text
  }
}

///|
fn resolved_entity_label(entity : Entity, locale : String) -> String {
  resolve_localized_text(entity.label, entity.labels, locale)
}

///|
fn resolved_state_label(entity : Entity, state_name : String, locale : String) -> String {
  for state in entity.states {
    if state.name == state_name {
      return resolve_localized_text(state.label, state.labels, locale)
    }
  }
  state_name
}

///|
fn resolved_field_label(entity : Entity, field_name : String, locale : String) -> String {
  for field in entity.fields {
    if field.name == field_name {
      return resolve_localized_text(field.label, field.labels, locale)
    }
  }
  field_name
}

///|
fn resolved_transition_input_label(
  entity : Entity,
  input : TransitionInput,
  locale : String,
) -> String {
  match input.kind {
    TransitionInputKind::EntityField => resolved_field_label(entity, input.name, locale)
    TransitionInputKind::Local => input.name
  }
}
