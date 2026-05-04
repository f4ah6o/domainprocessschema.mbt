///|
fn render_migration_sql(schema : Schema) -> String {
  let up_statements : Array[String] = []
  for entity in schema.entities {
    up_statements.push(render_create_table(schema, entity))
    for index_key in entity.indexes {
      up_statements.push(render_index(entity, index_key))
    }
  }

  let down_statements : Array[String] = []
  append_drop_statements(
    schema.entities,
    schema.entities.length() - 1,
    down_statements,
  )

  let up_block = up_statements.join("\n\n")
  let down_block = down_statements.join("\n")
  "-- migrate:up\n\{up_block}\n\n-- migrate:down\n\{down_block}"
}

///|
fn append_drop_statements(
  entities : Array[Entity],
  index : Int,
  down_statements : Array[String],
) -> Unit {
  if index < 0 {
    ()
  } else {
    let entity = entities[index]
    down_statements.push("DROP TABLE IF EXISTS \{entity.table_name};")
    append_drop_statements(entities, index - 1, down_statements)
  }
}
