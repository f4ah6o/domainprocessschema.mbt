///|
enum YamlValue {
  YamlScalar(String)
  YamlMap(Map[String, YamlValue])
  YamlList(Array[YamlValue])
} derive(Eq, Debug)

///|
struct YamlLine {
  line_no : Int
  indent : Int
  content : String
} derive(Eq, Debug)

///|
fn parse_yaml_document(input : String) -> YamlValue raise SchemaError {
  let normalized = input
    .replace_all(old="\r\n", new="\n")
    .replace_all(old="\r", new="\n")
  let lines = collect_yaml_lines(normalized)
  if lines.length() == 0 {
    raise schema_parse_error(
      line=1,
      "expected a YAML document, but the input was empty",
    )
  }
  let (value, next_index) = parse_yaml_node(lines, 0, lines[0].indent)
  if next_index != lines.length() {
    let line = lines[next_index]
    raise schema_parse_error(
      line=line.line_no,
      "unexpected trailing content at the top level",
    )
  }
  value
}

///|
fn collect_yaml_lines(input : String) -> Array[YamlLine] raise SchemaError {
  let collected : Array[YamlLine] = []
  for i, raw_line in input.split("\n").to_array() {
    if raw_line.contains_char('\t') {
      raise schema_parse_error(
        line=i + 1,
        "tabs are not supported; use spaces for indentation",
      )
    }
    let trimmed = raw_line.trim()
    if trimmed.is_empty() || trimmed.has_prefix("#") {
      continue
    }
    let indent = match raw_line.find_by(c => c != ' ') {
      Some(offset) => offset
      None => raw_line.length()
    }
    let content = raw_line.sub(start=indent).trim_end().to_string()
    collected.push(YamlLine::{ line_no: i + 1, indent, content })
  }
  collected
}

///|
fn parse_yaml_node(
  lines : Array[YamlLine],
  index : Int,
  indent : Int,
) -> (YamlValue, Int) raise SchemaError {
  guard index < lines.length() else {
    raise schema_parse_error(
      line=1,
      "expected a YAML node, but reached the end of the document",
    )
  }
  let line = lines[index]
  if line.content.has_prefix("-") {
    parse_yaml_list(lines, index, indent)
  } else {
    parse_yaml_map(lines, index, indent)
  }
}

///|
fn parse_yaml_map(
  lines : Array[YamlLine],
  index : Int,
  indent : Int,
) -> (YamlValue, Int) raise SchemaError {
  let entries : Map[String, YamlValue] = {}
  parse_yaml_map_entries(lines, index, indent, entries)
}

///|
fn parse_yaml_map_entries(
  lines : Array[YamlLine],
  index : Int,
  indent : Int,
  entries : Map[String, YamlValue],
) -> (YamlValue, Int) raise SchemaError {
  if index >= lines.length() {
    (YamlValue::YamlMap(entries), index)
  } else {
    let line = lines[index]
    if line.indent < indent {
      (YamlValue::YamlMap(entries), index)
    } else if line.indent > indent {
      raise schema_parse_error(
        line=line.line_no,
        "unexpected indentation inside a mapping",
      )
    } else if line.content.has_prefix("-") {
      raise schema_parse_error(
        line=line.line_no,
        "cannot mix sequence items and mapping entries at the same indentation level",
      )
    } else {
      let (key, inline_value) = parse_mapping_head(line)
      if entries.contains(key) {
        raise schema_parse_error(line=line.line_no, "duplicate key \{key}")
      }
      let (value, next_index) = match inline_value {
        Some(value) => (value, index + 1)
        None => parse_nested_child(lines, index, indent, "mapping value")
      }
      entries[key] = value
      parse_yaml_map_entries(lines, next_index, indent, entries)
    }
  }
}

///|
fn parse_mapping_head(
  line : YamlLine,
) -> (String, YamlValue?) raise SchemaError {
  match line.content.split_once(":") {
    Some((raw_key, raw_value)) => {
      let key = raw_key.trim()
      if key.is_empty() {
        raise schema_parse_error(
          line=line.line_no,
          "mapping keys must not be empty",
        )
      }
      let value_text = raw_value.trim_start()
      if value_text.is_empty() {
        (key.to_string(), None)
      } else {
        (
          key.to_string(),
          Some(parse_inline_yaml_value(value_text.to_string(), line.line_no)),
        )
      }
    }
    None =>
      raise schema_parse_error(
        line=line.line_no,
        "expected a `key: value` mapping entry",
      )
  }
}

///|
fn parse_nested_child(
  lines : Array[YamlLine],
  index : Int,
  indent : Int,
  expectation : String,
) -> (YamlValue, Int) raise SchemaError {
  let next_index = index + 1
  if next_index >= lines.length() {
    let line = lines[index]
    raise schema_parse_error(
      line=line.line_no,
      "expected a nested \{expectation}, but the document ended early",
    )
  }
  let next_line = lines[next_index]
  if next_line.indent <= indent {
    raise schema_parse_error(
      line=next_line.line_no,
      "expected an indented \{expectation}",
    )
  }
  parse_yaml_node(lines, next_index, next_line.indent)
}

///|
fn parse_yaml_list(
  lines : Array[YamlLine],
  index : Int,
  indent : Int,
) -> (YamlValue, Int) raise SchemaError {
  let items : Array[YamlValue] = []
  parse_yaml_list_items(lines, index, indent, items)
}

///|
fn parse_yaml_list_items(
  lines : Array[YamlLine],
  index : Int,
  indent : Int,
  items : Array[YamlValue],
) -> (YamlValue, Int) raise SchemaError {
  if index >= lines.length() {
    (YamlValue::YamlList(items), index)
  } else {
    let line = lines[index]
    if line.indent < indent {
      (YamlValue::YamlList(items), index)
    } else if line.indent > indent {
      raise schema_parse_error(
        line=line.line_no,
        "unexpected indentation inside a sequence",
      )
    } else if !line.content.has_prefix("-") {
      (YamlValue::YamlList(items), index)
    } else {
      let (item, next_index) = parse_yaml_list_item(lines, index, indent)
      items.push(item)
      parse_yaml_list_items(lines, next_index, indent, items)
    }
  }
}

///|
fn parse_yaml_list_item(
  lines : Array[YamlLine],
  index : Int,
  indent : Int,
) -> (YamlValue, Int) raise SchemaError {
  let line = lines[index]
  let rest = match line.content.split_once("-") {
    Some((before, after)) =>
      if before.is_empty() {
        after.trim_start().to_string()
      } else {
        raise schema_parse_error(
          line=line.line_no,
          "sequence items must start with `-`",
        )
      }
    None =>
      raise schema_parse_error(
        line=line.line_no,
        "sequence items must start with `-`",
      )
  }
  if rest.is_empty() {
    parse_nested_child(lines, index, indent, "sequence item")
  } else if rest.contains(":") {
    let entries : Map[String, YamlValue] = {}
    let (key, value) = parse_inline_mapping_entry(rest, line.line_no)
    entries[key] = value
    let next_index = index + 1
    if next_index < lines.length() && lines[next_index].indent > indent {
      let (extra, done) = parse_yaml_node(
        lines,
        next_index,
        lines[next_index].indent,
      )
      match extra {
        YamlValue::YamlMap(extra_entries) => {
          for extra_key, extra_value in extra_entries {
            if entries.contains(extra_key) {
              raise schema_parse_error(
                line=lines[next_index].line_no,
                "duplicate key \{extra_key} inside sequence item",
              )
            }
            entries[extra_key] = extra_value
          }
          (YamlValue::YamlMap(entries), done)
        }
        _ =>
          raise schema_parse_error(
            line=lines[next_index].line_no,
            "sequence item mappings can only merge with another mapping block",
          )
      }
    } else {
      (YamlValue::YamlMap(entries), next_index)
    }
  } else {
    (parse_inline_yaml_value(rest, line.line_no), index + 1)
  }
}

///|
fn parse_inline_mapping_entry(
  text : String,
  line_no : Int,
) -> (String, YamlValue) raise SchemaError {
  match text.split_once(":") {
    Some((raw_key, raw_value)) => {
      let key = raw_key.trim()
      let value_text = raw_value.trim()
      if key.is_empty() {
        raise schema_parse_error(line=line_no, "mapping keys must not be empty")
      }
      if value_text.is_empty() {
        raise schema_parse_error(
          line=line_no,
          "inline mapping entries must contain a value",
        )
      }
      (
        key.to_string(),
        parse_inline_yaml_value(value_text.to_string(), line_no),
      )
    }
    None =>
      raise schema_parse_error(
        line=line_no,
        "expected an inline `key: value` entry",
      )
  }
}

///|
fn parse_inline_yaml_value(
  text : String,
  line_no : Int,
) -> YamlValue raise SchemaError {
  let trimmed = text.trim()
  if trimmed.is_empty() {
    raise schema_parse_error(line=line_no, "inline values must not be empty")
  }
  if trimmed.has_prefix("[") && trimmed.has_suffix("]") {
    let prefix = match trimmed.strip_prefix("[") {
      Some(prefix) => prefix
      None => raise schema_parse_error(line=line_no, "invalid inline list")
    }
    let inner = match prefix.strip_suffix("]") {
      Some(inner) => inner
      None => raise schema_parse_error(line=line_no, "invalid inline list")
    }
    let items : Array[YamlValue] = []
    let inner_trimmed = inner.trim()
    if inner_trimmed.is_empty() {
      YamlValue::YamlList(items)
    } else {
      for part in inner.split(",") {
        let item = part.trim()
        if item.is_empty() {
          raise schema_parse_error(
            line=line_no,
            "inline lists must not contain empty elements",
          )
        }
        items.push(YamlValue::YamlScalar(item.to_string()))
      }
      YamlValue::YamlList(items)
    }
  } else {
    YamlValue::YamlScalar(trimmed.to_string())
  }
}
