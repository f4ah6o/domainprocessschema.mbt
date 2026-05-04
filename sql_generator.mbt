///|
fn render_sql(schema : Schema) -> String {
  let statements : Array[String] = []
  for entity in schema.entities {
    statements.push(render_create_table(schema, entity))
    for index_key in entity.indexes {
      statements.push(render_index(entity, index_key))
    }
  }
  statements.join("\n\n")
}

///|
fn render_create_table(schema : Schema, entity : Entity) -> String {
  let parts : Array[String] = []
  for field in entity.fields {
    parts.push(render_column(field))
  }
  for field in entity.fields {
    if field.field_type == FieldType::Ref {
      parts.push(render_foreign_key(schema, field))
    }
  }
  for constraint in entity.constraints {
    parts.push(render_check_constraint(entity, constraint))
  }
  for unique_key in entity.unique_keys {
    parts.push(render_unique_constraint(entity, unique_key))
  }
  let body = parts.map(part => "  \{part}").join(",\n")
  "CREATE TABLE \{entity.table_name} (\n\{body}\n);"
}

///|
fn render_column(field : Field) -> String {
  let column_parts : Array[String] = []
  column_parts.push(field.column_name)
  column_parts.push(sql_type(field.field_type))
  if field.primary {
    column_parts.push("PRIMARY KEY")
  }
  if field.primary || field.required || field.system {
    column_parts.push("NOT NULL")
  }
  match render_default_clause(field) {
    Some(default_clause) => column_parts.push(default_clause)
    None => ()
  }
  column_parts.join(" ")
}

///|
fn render_default_clause(field : Field) -> String? {
  match field.default_value {
    Some(default_value) =>
      Some("DEFAULT \{render_sql_literal(default_value, field.field_type)}")
    None =>
      match field.initial {
        Some(initial) =>
          if field.field_type == FieldType::State {
            Some("DEFAULT \{render_sql_literal(initial, field.field_type)}")
          } else {
            None
          }
        None => None
      }
  }
}

///|
fn render_foreign_key(schema : Schema, field : Field) -> String {
  let target_name = field.target.unwrap_or("")
  let target_entity = find_entity(schema, target_name)
  let target_primary = find_primary_field(target_entity)
  "FOREIGN KEY (\{field.column_name}) REFERENCES \{target_entity.table_name}(\{target_primary.column_name})"
}

///|
fn render_check_constraint(entity : Entity, constraint : Constraint) -> String {
  let field_map = entity_field_map(entity)
  let expr = expr_to_sql(constraint.expr, field_map, 0)
  "CHECK (\{expr})"
}

///|
fn render_unique_constraint(entity : Entity, unique_key : StorageKey) -> String {
  let columns = storage_key_columns(entity, unique_key)
  let joined = columns.join(", ")
  "UNIQUE (\{joined})"
}

///|
fn render_index(entity : Entity, index_key : StorageKey) -> String {
  let columns = storage_key_columns(entity, index_key)
  let joined_with_underscore = columns.join("_")
  let joined_with_comma = columns.join(", ")
  let index_name = "idx_\{entity.table_name}_\{joined_with_underscore}"
  "CREATE INDEX \{index_name} ON \{entity.table_name} (\{joined_with_comma});"
}

///|
fn storage_key_columns(entity : Entity, key : StorageKey) -> Array[String] {
  let field_map = entity_field_map(entity)
  let columns : Array[String] = []
  for name in key.fields {
    columns.push(field_map[name].column_name)
  }
  columns
}

///|
fn entity_field_map(entity : Entity) -> Map[String, Field] {
  let fields : Map[String, Field] = {}
  for field in entity.fields {
    fields[field.name] = field
  }
  fields
}

///|
fn find_entity(schema : Schema, name : String) -> Entity {
  for entity in schema.entities {
    if entity.name == name {
      return entity
    }
  }
  abort("validated schema lost entity \{name}")
}

///|
fn find_primary_field(entity : Entity) -> Field {
  for field in entity.fields {
    if field.primary {
      return field
    }
  }
  abort("validated entity \{entity.name} lost its primary field")
}

///|
fn sql_type(field_type : FieldType) -> String {
  match field_type {
    FieldType::Id => "TEXT"
    FieldType::Text => "TEXT"
    FieldType::Number => "INTEGER"
    FieldType::Money => "INTEGER"
    FieldType::Boolean => "BOOLEAN"
    FieldType::Date => "TEXT"
    FieldType::DateTime => "TEXT"
    FieldType::Enum => "TEXT"
    FieldType::Ref => "TEXT"
    FieldType::State => "TEXT"
    FieldType::File => "TEXT"
  }
}

///|
fn render_sql_literal(value : String, field_type : FieldType) -> String {
  match field_type {
    FieldType::Boolean =>
      match normalize_token(value) {
        "true" => "TRUE"
        "false" => "FALSE"
        _ => quote_sql(value)
      }
    FieldType::Number | FieldType::Money =>
      if is_integer_literal(value) {
        value
      } else {
        quote_sql(value)
      }
    _ => quote_sql(value)
  }
}

///|
fn quote_sql(value : String) -> String {
  let escaped = value.replace_all(old="'", new="''")
  "'\{escaped}'"
}

///|
fn is_integer_literal(value : String) -> Bool {
  let trimmed = value.trim()
  if trimmed.is_empty() {
    false
  } else {
    let chars = trimmed.to_array()
    for i, char in chars {
      if i == 0 && char == '-' {
        continue
      }
      if !(char is ('0'..='9')) {
        return false
      }
    }
    true
  }
}

///|
fn expr_to_sql(
  expr : Expr,
  field_map : Map[String, Field],
  parent_prec : Int,
) -> String {
  match expr {
    Expr::Path(parts) =>
      if parts.length() == 1 {
        match field_map.get(parts[0]) {
          Some(field) => field.column_name
          None => parts.join(".")
        }
      } else {
        parts.join(".")
      }
    Expr::StringLiteral(text) => quote_sql(text)
    Expr::NumberLiteral(text) => text
    Expr::BoolLiteral(value) => if value { "TRUE" } else { "FALSE" }
    Expr::Not(inner) => {
      let rendered = "NOT \{expr_to_sql(inner, field_map, 4)}"
      if parent_prec > 4 {
        "(\{rendered})"
      } else {
        rendered
      }
    }
    Expr::Binary(op, left, right) => {
      let prec = binary_precedence(op)
      let op_text = binary_op_sql_text(op)
      let left_text = expr_to_sql(left, field_map, prec)
      let right_text = expr_to_sql(right, field_map, prec + 1)
      let rendered = "\{left_text} \{op_text} \{right_text}"
      if parent_prec > prec {
        "(\{rendered})"
      } else {
        rendered
      }
    }
  }
}

///|
fn binary_op_sql_text(op : BinaryOp) -> String {
  match op {
    BinaryOp::Or => "OR"
    BinaryOp::And => "AND"
    BinaryOp::Eq => "="
    BinaryOp::NotEq => "!="
    BinaryOp::Gt => ">"
    BinaryOp::Gte => ">="
    BinaryOp::Lt => "<"
    BinaryOp::Lte => "<="
  }
}

///|
fn sql_column_name(name : String, field_type : FieldType) -> String {
  let base = camel_to_snake(name)
  if field_type == FieldType::Ref && !base.has_suffix("_id") {
    "\{base}_id"
  } else {
    base
  }
}

///|
fn pluralize_snake(name : String) -> String {
  let snake = camel_to_snake(name)
  if snake.has_suffix("s") {
    snake
  } else {
    "\{snake}s"
  }
}

///|
fn camel_to_snake(name : String) -> String {
  let builder = StringBuilder::new()
  let mut wrote_any = false
  let mut previous_lower_or_digit = false
  for char in name {
    if char is ('A'..='Z') {
      if wrote_any && previous_lower_or_digit {
        builder.write_char('_')
      }
      builder.write_char(char.to_ascii_lowercase())
      wrote_any = true
      previous_lower_or_digit = false
    } else if char == '-' || char == ' ' {
      if wrote_any {
        builder.write_char('_')
      }
      previous_lower_or_digit = false
    } else {
      builder.write_char(char)
      wrote_any = true
      previous_lower_or_digit = char is ('a'..='z') || char is ('0'..='9')
    }
  }
  builder.to_string()
}
