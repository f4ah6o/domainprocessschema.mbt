///|
enum ExprToken {
  Ident(String)
  Number(String)
  StringLit(String)
  BoolLit(Bool)
  Dot
  LParen
  RParen
  AndAnd
  OrOr
  EqEq
  NotEq
  Gt
  Gte
  Lt
  Lte
  Bang
} derive(Eq, Show)

///|
fn parse_expr_text(input : String, path : String) -> Expr raise SchemaError {
  let tokens = tokenize_expr(input, path)
  if tokens.length() == 0 {
    raise schema_validation_error(
      path~,
      "expression must not be empty",
      code="INVALID_EXPR",
    )
  }
  let (expr, next_index) = parse_or_expr(tokens, 0, path)
  if next_index != tokens.length() {
    raise schema_validation_error(
      path~,
      "unexpected trailing tokens in expression",
      code="INVALID_EXPR",
    )
  }
  expr
}

///|
fn tokenize_expr(
  input : String,
  path : String,
) -> Array[ExprToken] raise SchemaError {
  let chars = input.to_array()
  let tokens : Array[ExprToken] = []
  tokenize_expr_chars(chars, 0, tokens, path)
}

///|
fn tokenize_expr_chars(
  chars : Array[Char],
  index : Int,
  tokens : Array[ExprToken],
  path : String,
) -> Array[ExprToken] raise SchemaError {
  if index >= chars.length() {
    tokens
  } else {
    let char = chars[index]
    if char == ' ' || char == '\n' || char == '\r' || char == '\t' {
      tokenize_expr_chars(chars, index + 1, tokens, path)
    } else if is_expr_ident_start(char) {
      let (ident, next_index) = read_ident_token(chars, index)
      let normalized = normalize_token(ident)
      if normalized == "true" {
        tokens.push(ExprToken::BoolLit(true))
      } else if normalized == "false" {
        tokens.push(ExprToken::BoolLit(false))
      } else {
        tokens.push(ExprToken::Ident(ident))
      }
      tokenize_expr_chars(chars, next_index, tokens, path)
    } else if char is ('0'..='9') {
      let (number, next_index) = read_number_token(chars, index)
      tokens.push(ExprToken::Number(number))
      tokenize_expr_chars(chars, next_index, tokens, path)
    } else {
      match char {
        '(' => {
          tokens.push(ExprToken::LParen)
          tokenize_expr_chars(chars, index + 1, tokens, path)
        }
        ')' => {
          tokens.push(ExprToken::RParen)
          tokenize_expr_chars(chars, index + 1, tokens, path)
        }
        '.' => {
          tokens.push(ExprToken::Dot)
          tokenize_expr_chars(chars, index + 1, tokens, path)
        }
        '!' =>
          if index + 1 < chars.length() && chars[index + 1] == '=' {
            tokens.push(ExprToken::NotEq)
            tokenize_expr_chars(chars, index + 2, tokens, path)
          } else {
            tokens.push(ExprToken::Bang)
            tokenize_expr_chars(chars, index + 1, tokens, path)
          }
        '=' =>
          if index + 1 < chars.length() && chars[index + 1] == '=' {
            tokens.push(ExprToken::EqEq)
            tokenize_expr_chars(chars, index + 2, tokens, path)
          } else {
            raise schema_validation_error(
              path~,
              "single `=` is not valid in expressions; use `==`",
              code="INVALID_EXPR",
            )
          }
        '&' =>
          if index + 1 < chars.length() && chars[index + 1] == '&' {
            tokens.push(ExprToken::AndAnd)
            tokenize_expr_chars(chars, index + 2, tokens, path)
          } else {
            raise schema_validation_error(
              path~,
              "single `&` is not valid in expressions; use `&&`",
              code="INVALID_EXPR",
            )
          }
        '|' =>
          if index + 1 < chars.length() && chars[index + 1] == '|' {
            tokens.push(ExprToken::OrOr)
            tokenize_expr_chars(chars, index + 2, tokens, path)
          } else {
            raise schema_validation_error(
              path~,
              "single `|` is not valid in expressions; use `||`",
              code="INVALID_EXPR",
            )
          }
        '>' =>
          if index + 1 < chars.length() && chars[index + 1] == '=' {
            tokens.push(ExprToken::Gte)
            tokenize_expr_chars(chars, index + 2, tokens, path)
          } else {
            tokens.push(ExprToken::Gt)
            tokenize_expr_chars(chars, index + 1, tokens, path)
          }
        '<' =>
          if index + 1 < chars.length() && chars[index + 1] == '=' {
            tokens.push(ExprToken::Lte)
            tokenize_expr_chars(chars, index + 2, tokens, path)
          } else {
            tokens.push(ExprToken::Lt)
            tokenize_expr_chars(chars, index + 1, tokens, path)
          }
        '"' => {
          let (literal, next_index) = read_string_token(chars, index + 1, path)
          tokens.push(ExprToken::StringLit(literal))
          tokenize_expr_chars(chars, next_index, tokens, path)
        }
        _ =>
          raise schema_validation_error(
            path~,
            "unsupported character in expression",
            code="INVALID_EXPR",
          )
      }
    }
  }
}

///|
fn read_ident_token(chars : Array[Char], index : Int) -> (String, Int) {
  let builder = StringBuilder::new()
  read_ident_token_chars(chars, index, builder)
}

///|
fn read_ident_token_chars(
  chars : Array[Char],
  index : Int,
  builder : StringBuilder,
) -> (String, Int) {
  if index >= chars.length() {
    (builder.to_string(), index)
  } else {
    let char = chars[index]
    if is_expr_ident_continue(char) {
      builder.write_char(char)
      read_ident_token_chars(chars, index + 1, builder)
    } else {
      (builder.to_string(), index)
    }
  }
}

///|
fn read_number_token(chars : Array[Char], index : Int) -> (String, Int) {
  let builder = StringBuilder::new()
  read_number_token_chars(chars, index, builder)
}

///|
fn read_number_token_chars(
  chars : Array[Char],
  index : Int,
  builder : StringBuilder,
) -> (String, Int) {
  if index >= chars.length() {
    (builder.to_string(), index)
  } else {
    let char = chars[index]
    if char is ('0'..='9') {
      builder.write_char(char)
      read_number_token_chars(chars, index + 1, builder)
    } else {
      (builder.to_string(), index)
    }
  }
}

///|
fn read_string_token(
  chars : Array[Char],
  index : Int,
  path : String,
) -> (String, Int) raise SchemaError {
  let builder = StringBuilder::new()
  read_string_token_chars(chars, index, builder, path)
}

///|
fn read_string_token_chars(
  chars : Array[Char],
  index : Int,
  builder : StringBuilder,
  path : String,
) -> (String, Int) raise SchemaError {
  if index >= chars.length() {
    raise schema_validation_error(
      path~,
      "unterminated string literal",
      code="INVALID_EXPR",
    )
  } else {
    let char = chars[index]
    if char == '"' {
      (builder.to_string(), index + 1)
    } else {
      builder.write_char(char)
      read_string_token_chars(chars, index + 1, builder, path)
    }
  }
}

///|
fn is_expr_ident_start(char : Char) -> Bool {
  char is ('a'..='z') || char is ('A'..='Z') || char == '_'
}

///|
fn is_expr_ident_continue(char : Char) -> Bool {
  is_expr_ident_start(char) || char is ('0'..='9')
}

///|
fn parse_or_expr(
  tokens : Array[ExprToken],
  index : Int,
  path : String,
) -> (Expr, Int) raise SchemaError {
  let (left, next_index) = parse_and_expr(tokens, index, path)
  parse_or_expr_tail(tokens, next_index, left, path)
}

///|
fn parse_or_expr_tail(
  tokens : Array[ExprToken],
  index : Int,
  left : Expr,
  path : String,
) -> (Expr, Int) raise SchemaError {
  if index < tokens.length() && tokens[index] == ExprToken::OrOr {
    let (right, next_index) = parse_and_expr(tokens, index + 1, path)
    parse_or_expr_tail(
      tokens,
      next_index,
      Expr::Binary(BinaryOp::Or, left, right),
      path,
    )
  } else {
    (left, index)
  }
}

///|
fn parse_and_expr(
  tokens : Array[ExprToken],
  index : Int,
  path : String,
) -> (Expr, Int) raise SchemaError {
  let (left, next_index) = parse_comparison_expr(tokens, index, path)
  parse_and_expr_tail(tokens, next_index, left, path)
}

///|
fn parse_and_expr_tail(
  tokens : Array[ExprToken],
  index : Int,
  left : Expr,
  path : String,
) -> (Expr, Int) raise SchemaError {
  if index < tokens.length() && tokens[index] == ExprToken::AndAnd {
    let (right, next_index) = parse_comparison_expr(tokens, index + 1, path)
    parse_and_expr_tail(
      tokens,
      next_index,
      Expr::Binary(BinaryOp::And, left, right),
      path,
    )
  } else {
    (left, index)
  }
}

///|
fn parse_comparison_expr(
  tokens : Array[ExprToken],
  index : Int,
  path : String,
) -> (Expr, Int) raise SchemaError {
  let (left, next_index) = parse_unary_expr(tokens, index, path)
  if next_index < tokens.length() {
    match comparison_op(tokens[next_index]) {
      Some(op) => {
        let (right, done) = parse_unary_expr(tokens, next_index + 1, path)
        (Expr::Binary(op, left, right), done)
      }
      None => (left, next_index)
    }
  } else {
    (left, next_index)
  }
}

///|
fn comparison_op(token : ExprToken) -> BinaryOp? {
  match token {
    ExprToken::EqEq => Some(BinaryOp::Eq)
    ExprToken::NotEq => Some(BinaryOp::NotEq)
    ExprToken::Gt => Some(BinaryOp::Gt)
    ExprToken::Gte => Some(BinaryOp::Gte)
    ExprToken::Lt => Some(BinaryOp::Lt)
    ExprToken::Lte => Some(BinaryOp::Lte)
    _ => None
  }
}

///|
fn parse_unary_expr(
  tokens : Array[ExprToken],
  index : Int,
  path : String,
) -> (Expr, Int) raise SchemaError {
  if index < tokens.length() && tokens[index] == ExprToken::Bang {
    let (inner, next_index) = parse_unary_expr(tokens, index + 1, path)
    (Expr::Not(inner), next_index)
  } else {
    parse_primary_expr(tokens, index, path)
  }
}

///|
fn parse_primary_expr(
  tokens : Array[ExprToken],
  index : Int,
  path : String,
) -> (Expr, Int) raise SchemaError {
  if index >= tokens.length() {
    raise schema_validation_error(
      path~,
      "unexpected end of expression",
      code="INVALID_EXPR",
    )
  } else {
    match tokens[index] {
      ExprToken::Ident(name) => parse_path_expr(tokens, index + 1, [name], path)
      ExprToken::Number(number) => (Expr::NumberLiteral(number), index + 1)
      ExprToken::StringLit(text) => (Expr::StringLiteral(text), index + 1)
      ExprToken::BoolLit(value) => (Expr::BoolLiteral(value), index + 1)
      ExprToken::LParen => {
        let (inner, next_index) = parse_or_expr(tokens, index + 1, path)
        if next_index >= tokens.length() ||
          tokens[next_index] != ExprToken::RParen {
          raise schema_validation_error(
            path~,
            "missing closing `)`",
            code="INVALID_EXPR",
          )
        }
        (inner, next_index + 1)
      }
      _ =>
        raise schema_validation_error(
          path~,
          "expected a primary expression",
          code="INVALID_EXPR",
        )
    }
  }
}

///|
fn parse_path_expr(
  tokens : Array[ExprToken],
  index : Int,
  parts : Array[String],
  path : String,
) -> (Expr, Int) raise SchemaError {
  if index + 1 < tokens.length() && tokens[index] == ExprToken::Dot {
    match tokens[index + 1] {
      ExprToken::Ident(name) => {
        parts.push(name)
        parse_path_expr(tokens, index + 2, parts, path)
      }
      _ =>
        raise schema_validation_error(
          path~,
          "expected identifier after `.`",
          code="INVALID_EXPR",
        )
    }
  } else {
    (Expr::Path(parts), index)
  }
}

///|
fn validate_expr(
  expr : Expr,
  field_names : Map[String, Field],
  path : String,
  allow_state : Bool,
  allow_user : Bool,
) -> Unit raise SchemaError {
  match expr {
    Expr::Path(parts) =>
      validate_expr_path(parts, field_names, path, allow_state, allow_user)
    Expr::Not(inner) =>
      validate_expr(inner, field_names, path, allow_state, allow_user)
    Expr::Binary(_, left, right) => {
      validate_expr(left, field_names, path, allow_state, allow_user)
      validate_expr(right, field_names, path, allow_state, allow_user)
    }
    _ => ()
  }
}

///|
fn validate_expr_path(
  parts : Array[String],
  field_names : Map[String, Field],
  path : String,
  allow_state : Bool,
  allow_user : Bool,
) -> Unit raise SchemaError {
  if parts.length() == 1 && field_names.contains(parts[0]) {
    ()
  } else if allow_state && parts.length() == 1 && parts[0] == "state" {
    ()
  } else if allow_user && parts.length() >= 2 && parts[0] == "user" {
    ()
  } else {
    let rendered = parts.join(".")
    raise schema_validation_error(
      path~,
      "unknown identifier path \{rendered}",
      code="INVALID_EXPR",
      hint="Use a declared field name, `state`, or `user.<attr>` where that context is allowed.",
    )
  }
}

///|
fn expr_to_string(expr : Expr) -> String {
  render_expr(expr, 0)
}

///|
fn render_expr(expr : Expr, parent_prec : Int) -> String {
  match expr {
    Expr::Path(parts) => parts.join(".")
    Expr::StringLiteral(text) => "\"\{text}\""
    Expr::NumberLiteral(text) => text
    Expr::BoolLiteral(value) => if value { "true" } else { "false" }
    Expr::Not(inner) => {
      let rendered = "!\{render_expr(inner, 4)}"
      if parent_prec > 4 {
        "(\{rendered})"
      } else {
        rendered
      }
    }
    Expr::Binary(op, left, right) => {
      let prec = binary_precedence(op)
      let op_text = binary_op_text(op)
      let left_text = render_expr(left, prec)
      let right_text = render_expr(right, prec + 1)
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
fn binary_precedence(op : BinaryOp) -> Int {
  match op {
    BinaryOp::Or => 1
    BinaryOp::And => 2
    _ => 3
  }
}

///|
fn binary_op_text(op : BinaryOp) -> String {
  match op {
    BinaryOp::Or => "||"
    BinaryOp::And => "&&"
    BinaryOp::Eq => "=="
    BinaryOp::NotEq => "!="
    BinaryOp::Gt => ">"
    BinaryOp::Gte => ">="
    BinaryOp::Lt => "<"
    BinaryOp::Lte => "<="
  }
}
