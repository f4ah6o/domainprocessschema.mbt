///|
fn render_api_manifest(schema : Schema) -> String {
  let rendered_entities : Array[String] = []
  for entity in schema.entities {
    rendered_entities.push(render_api_entity(entity))
  }
  let entities_block = indent_block(rendered_entities.join(",\n"), 4)
  "{\n  \"entities\": [\n\{entities_block}\n  ]\n}"
}

///|
fn render_api_entity(entity : Entity) -> String {
  let rendered_fields : Array[String] = []
  for field in entity.fields {
    rendered_fields.push(render_api_field(field))
  }
  let rendered_routes = render_api_routes(entity)
  let rendered_actions = render_api_actions(entity)
  let body_lines = [
    "\"name\": \{json_quote(entity.name)}",
    "\"label\": \{json_quote(entity.label)}",
    "\"table\": \{json_quote(entity.table_name)}",
    render_named_object_array("fields", rendered_fields),
    render_named_object_array("routes", rendered_routes),
    render_named_object_array("actions", rendered_actions),
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_api_field(field : Field) -> String {
  let body_lines = [
    "\"name\": \{json_quote(field.name)}",
    "\"column\": \{json_quote(field.column_name)}",
    "\"type\": \{json_quote(field_type_name(field.field_type))}",
    "\"required\": \{json_bool(field.required)}",
    "\"primary\": \{json_bool(field.primary)}",
    "\"readOnly\": \{json_bool(field.read_only)}",
    "\"system\": \{json_bool(field.system)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_named_object_array(name : String, items : Array[String]) -> String {
  if items.length() == 0 {
    "\"\{name}\": []"
  } else {
    let block = indent_block(items.join(",\n"), 4)
    "\"\{name}\": [\n\{block}\n  ]"
  }
}

///|
fn render_api_routes(entity : Entity) -> Array[String] {
  let primary_field = find_primary_field(entity)
  let base_path = "/\{entity.table_name}"
  let item_param = "{\{primary_field.name}}"
  let item_path = "\{base_path}/\{item_param}"
  [
    render_api_route("GET", item_path),
    render_api_route("POST", base_path),
    render_api_route("PATCH", item_path),
  ]
}

///|
fn render_api_route(http_method : String, path : String) -> String {
  let body_lines = [
    "\"method\": \{json_quote(http_method)}",
    "\"path\": \{json_quote(path)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_api_actions(entity : Entity) -> Array[String] {
  let primary_field = find_primary_field(entity)
  let item_param = "{\{primary_field.name}}"
  let base_path = "/\{entity.table_name}/\{item_param}"
  let actions : Array[String] = []
  for transition in entity.transitions {
    let input_json = render_string_array_json(transition.input_fields)
    let guard_json = json_optional_expr(transition.guard_expr)
    let role_json = json_optional_string(transition.role)
    let action_path = "\{base_path}/\{transition.name}"
    let body_lines = [
      "\"name\": \{json_quote(transition.name)}",
      "\"from\": \{json_quote(transition.from)}",
      "\"to\": \{json_quote(transition.to)}",
      "\"path\": \{json_quote(action_path)}",
      "\"input\": \{input_json}",
      "\"guard\": \{guard_json}",
      "\"role\": \{role_json}",
    ]
    let body = indent_block(body_lines.join(",\n"), 2)
    actions.push("{\n\{body}\n}")
  }
  actions
}

///|
fn field_type_name(field_type : FieldType) -> String {
  match field_type {
    FieldType::Id => "id"
    FieldType::Text => "text"
    FieldType::Number => "number"
    FieldType::Money => "money"
    FieldType::Boolean => "boolean"
    FieldType::Date => "date"
    FieldType::DateTime => "datetime"
    FieldType::Enum => "enum"
    FieldType::Ref => "ref"
    FieldType::State => "state"
    FieldType::File => "file"
  }
}

///|
fn json_quote(value : String) -> String {
  "\"\{json_escape(value)}\""
}

///|
fn json_bool(value : Bool) -> String {
  if value {
    "true"
  } else {
    "false"
  }
}

///|
fn json_escape(value : String) -> String {
  let builder = StringBuilder::new()
  for char in value {
    if char == '\\' {
      builder.write_string("\\\\")
    } else if char == '"' {
      builder.write_string("\\\"")
    } else {
      builder.write_char(char)
    }
  }
  builder.to_string()
}

///|
fn json_optional_string(value : String?) -> String {
  match value {
    Some(text) => json_quote(text)
    None => "null"
  }
}

///|
fn json_optional_expr(value : Expr?) -> String {
  match value {
    Some(expr) => json_quote(expr_to_string(expr))
    None => "null"
  }
}

///|
fn render_string_array_json(values : Array[String]) -> String {
  let rendered = values.map(value => json_quote(value))
  let joined = rendered.join(", ")
  "[\{joined}]"
}

///|
fn indent_block(text : String, spaces : Int) -> String {
  let prefix = " ".repeat(spaces)
  let lines = text.split("\n").to_array()
  let indented : Array[String] = []
  for line in lines {
    indented.push("\{prefix}\{line}")
  }
  indented.join("\n")
}
