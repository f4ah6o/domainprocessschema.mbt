///|
fn runtime_eval_expr(
  entity : Entity,
  values : Map[String, RuntimeValue],
  actor : RuntimeActor,
  expr : Expr,
  path : String,
) -> Result[RuntimeValue, Diagnostic] {
  match expr {
    Expr::Path(parts) => runtime_eval_path(entity, values, actor, parts, path)
    Expr::StringLiteral(text) => Ok(RuntimeValue::Text(text))
    Expr::NumberLiteral(text) =>
      if is_integer_literal(text) {
        Ok(RuntimeValue::Integer(parse_runtime_integer(text)))
      } else {
        Err(
          runtime_issue(
            path,
            "only integer literals are currently supported",
            code="INVALID_EXPR",
          ),
        )
      }
    Expr::BoolLiteral(flag) => Ok(RuntimeValue::Flag(flag))
    Expr::Not(inner) =>
      match runtime_eval_expr(entity, values, actor, inner, path) {
        Ok(value) =>
          match runtime_value_to_bool(value, path) {
            Ok(flag) => Ok(RuntimeValue::Flag(!flag))
            Err(issue) => Err(issue)
          }
        Err(issue) => Err(issue)
      }
    Expr::Binary(op, left, right) =>
      match
        (
          runtime_eval_expr(entity, values, actor, left, path),
          runtime_eval_expr(entity, values, actor, right, path),
        ) {
        (Ok(left_value), Ok(right_value)) =>
          runtime_eval_binary(op, left_value, right_value, path)
        (Err(issue), _) => Err(issue)
        (_, Err(issue)) => Err(issue)
      }
  }
}

///|
fn runtime_eval_bool_expr(
  entity : Entity,
  values : Map[String, RuntimeValue],
  actor : RuntimeActor,
  expr : Expr,
  path : String,
) -> Result[Bool, Diagnostic] {
  match runtime_eval_expr(entity, values, actor, expr, path) {
    Ok(value) => runtime_value_to_bool(value, path)
    Err(issue) => Err(issue)
  }
}

///|
fn runtime_eval_path(
  entity : Entity,
  values : Map[String, RuntimeValue],
  actor : RuntimeActor,
  parts : Array[String],
  path : String,
) -> Result[RuntimeValue, Diagnostic] {
  if parts.length() == 1 {
    if parts[0] == "state" {
      match runtime_find_state_field(entity) {
        Some(state_field) =>
          match values.get(state_field.name) {
            Some(value) => Ok(value)
            None =>
              Err(
                runtime_issue(
                  path,
                  "state value is missing for entity \{entity.name}",
                  code="UNKNOWN_STATE",
                ),
              )
          }
        None =>
          Err(
            runtime_issue(
              path,
              "entity \{entity.name} does not define a state field",
              code="UNKNOWN_STATE",
            ),
          )
      }
    } else {
      match values.get(parts[0]) {
        Some(value) => Ok(value)
        None =>
          Err(
            runtime_issue(
              path,
              "missing runtime value for field \{parts[0]}",
              code="UNKNOWN_FIELD",
            ),
          )
      }
    }
  } else if parts.length() >= 2 && parts[0] == "user" {
    let actor_key = parts[1:].join(".")
    match actor.attributes.get(actor_key) {
      Some(value) => Ok(value)
      None =>
        Err(
          runtime_issue(
            path,
            "missing actor attribute \{actor_key}",
            code="INVALID_EXPR",
          ),
        )
    }
  } else {
    let rendered_path = parts.join(".")
    Err(
      runtime_issue(
        path,
        "unsupported runtime path \{rendered_path}",
        code="INVALID_EXPR",
      ),
    )
  }
}

///|
fn runtime_eval_binary(
  op : BinaryOp,
  left : RuntimeValue,
  right : RuntimeValue,
  path : String,
) -> Result[RuntimeValue, Diagnostic] {
  match op {
    BinaryOp::Or =>
      match
        (runtime_value_to_bool(left, path), runtime_value_to_bool(right, path)) {
        (Ok(left_bool), Ok(right_bool)) =>
          Ok(RuntimeValue::Flag(left_bool || right_bool))
        (Err(issue), _) => Err(issue)
        (_, Err(issue)) => Err(issue)
      }
    BinaryOp::And =>
      match
        (runtime_value_to_bool(left, path), runtime_value_to_bool(right, path)) {
        (Ok(left_bool), Ok(right_bool)) =>
          Ok(RuntimeValue::Flag(left_bool && right_bool))
        (Err(issue), _) => Err(issue)
        (_, Err(issue)) => Err(issue)
      }
    BinaryOp::Eq =>
      match runtime_value_equals(left, right) {
        Some(equal) => Ok(RuntimeValue::Flag(equal))
        None =>
          Err(
            runtime_issue(
              path,
              "cannot compare values with `==`",
              code="INVALID_EXPR",
            ),
          )
      }
    BinaryOp::NotEq =>
      match runtime_value_equals(left, right) {
        Some(equal) => Ok(RuntimeValue::Flag(!equal))
        None =>
          Err(
            runtime_issue(
              path,
              "cannot compare values with `!=`",
              code="INVALID_EXPR",
            ),
          )
      }
    BinaryOp::Gt | BinaryOp::Gte | BinaryOp::Lt | BinaryOp::Lte =>
      match runtime_value_compare(left, right) {
        Some(ordering) => {
          let result = match op {
            BinaryOp::Gt => ordering > 0
            BinaryOp::Gte => ordering >= 0
            BinaryOp::Lt => ordering < 0
            BinaryOp::Lte => ordering <= 0
            _ => false
          }
          Ok(RuntimeValue::Flag(result))
        }
        None =>
          Err(
            runtime_issue(
              path,
              "ordering comparisons require matching text or integer values",
              code="INVALID_EXPR",
            ),
          )
      }
  }
}
