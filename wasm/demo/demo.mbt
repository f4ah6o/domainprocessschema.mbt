///|
priv struct DemoPreview {
  record : @schema.RuntimeRecord
  actor : @schema.RuntimeActor
}

///|
pub(all) struct DemoSession {
  runtime : @schema.Runtime
  record : @schema.RuntimeRecord
  actor : @schema.RuntimeActor
} derive(Eq, Show)

///|
pub fn render_manifest_preview(
  yaml : String,
  locale? : String = "",
) -> Result[String, Error] {
  try @schema.compile_gui_html_from_yaml(yaml, locale=locale) catch {
    err => Err(err)
  } noraise {
    html => Ok(html)
  }
}

///|
pub fn render_runtime_preview(
  yaml : String,
  scenario : String,
  locale? : String = "",
) -> Result[String, Error] {
  try {
    let runtime = @schema.compile_runtime_from_yaml(yaml)
    match build_demo_preview(runtime, scenario) {
      Ok(preview) =>
        Ok(
          @schema.render_runtime_gui_html(
            runtime,
            preview.record,
            actor=preview.actor,
            locale=locale,
          ),
        )
      Err(err) => Err(err)
    }
  } catch {
    err => Err(err)
  }
}

///|
pub fn render_validation_manifest(yaml : String) -> Result[String, Error] {
  try @schema.compile_validation_manifest_from_yaml(yaml) catch {
    err => Err(err)
  } noraise {
    manifest => Ok(manifest)
  }
}

///|
pub fn create_demo_session(
  yaml : String,
  actor_role? : String = "",
) -> Result[DemoSession, Error] {
  try {
    let runtime = @schema.compile_runtime_from_yaml(yaml)
    let record = @schema.validate_record(
        runtime,
        "ExpenseRequest",
        draft_payload(),
      ).record
    Ok(DemoSession::{ runtime, record, actor: actor_for_role(actor_role) })
  } catch {
    err => Err(err)
  }
}

///|
pub fn session_preview_html(
  session : DemoSession,
  locale? : String = "",
) -> Result[String, Error] {
  try
    @schema.render_runtime_gui_html(
      session.runtime,
      session.record,
      actor=session.actor,
      locale=locale,
    )
  catch {
    err => Err(err)
  } noraise {
    html => Ok(html)
  }
}

///|
pub fn session_snapshot_json(
  session : DemoSession,
  locale? : String = "",
) -> Result[String, Error] {
  try {
    let view = @schema.project_gui(
      session.runtime,
      session.record,
      actor=session.actor,
      locale=locale,
    )
    Ok(render_demo_session_snapshot_json(session, view))
  } catch {
    err => Err(err)
  }
}

///|
pub fn apply_session_transition(
  session : DemoSession,
  transition_name : String,
  input_json : String,
) -> Result[DemoSession, Error] {
  try {
    let input = parse_demo_input_json(input_json)
    let record = @schema.apply_transition(
      session.runtime,
      session.record,
      transition_name,
      input~,
      actor=session.actor,
    )
    Ok(DemoSession::{ runtime: session.runtime, record, actor: session.actor })
  } catch {
    err => Err(err)
  }
}

///|
pub fn result_is_ok(res : Result[String, Error]) -> Bool {
  res is Ok(_)
}

///|
pub fn result_unwrap(res : Result[String, Error]) -> String {
  match res {
    Ok(html) => html
    Err(_) => ""
  }
}

///|
pub fn result_error(res : Result[String, Error]) -> String {
  match res {
    Ok(_) => ""
    Err(err) => "\{err}"
  }
}

///|
pub fn session_result_is_ok(res : Result[DemoSession, Error]) -> Bool {
  res is Ok(_)
}

///|
pub fn session_result_unwrap(res : Result[DemoSession, Error]) -> DemoSession {
  match res {
    Ok(session) => session
    Err(_) =>
      abort(
        "session_result_unwrap called with Err; guard with session_result_is_ok first",
      )
  }
}

///|
pub fn session_result_error(res : Result[DemoSession, Error]) -> String {
  match res {
    Ok(_) => ""
    Err(err) => "\{err}"
  }
}

///|
pub fn session_result_error_json(res : Result[DemoSession, Error]) -> String {
  match res {
    Ok(_) => render_demo_error_payload_json("ok", "", issues=[])
    Err(err) => render_demo_error_json(err)
  }
}

///|
fn build_demo_preview(
  runtime : @schema.Runtime,
  scenario : String,
) -> Result[DemoPreview, Error] raise {
  let draft = @schema.validate_record(
      runtime,
      "ExpenseRequest",
      draft_payload(),
    ).record
  let anonymous = @schema.RuntimeActor::anonymous()
  let manager = manager_actor()
  let submitted = @schema.apply_transition(runtime, draft, "submit", input={
    "amount": @schema.RuntimeValue::Integer(1200),
    "reason": @schema.RuntimeValue::Text("hotel"),
  })
  match scenario {
    "draft" => Ok(DemoPreview::{ record: draft, actor: anonymous })
    "submitted" => Ok(DemoPreview::{ record: submitted, actor: anonymous })
    "submitted-manager" =>
      Ok(DemoPreview::{ record: submitted, actor: manager })
    "approved-manager" => {
      let approved = @schema.apply_transition(
        runtime,
        submitted,
        "approve",
        actor=manager,
      )
      Ok(DemoPreview::{ record: approved, actor: manager })
    }
    "rejected-manager" => {
      let rejected = @schema.apply_transition(
        runtime,
        submitted,
        "reject",
        input={
          "rejectReason": @schema.RuntimeValue::Text("budget over threshold"),
        },
        actor=manager,
      )
      Ok(DemoPreview::{ record: rejected, actor: manager })
    }
    _ =>
      Err(
        @builtin.Failure::Failure(
          "unsupported preview scenario \{scenario}; use `draft`, `submitted`, `submitted-manager`, `approved-manager`, or `rejected-manager`",
        ),
      )
  }
}

///|
fn draft_payload() -> Map[String, @schema.RuntimeValue] {
  {
    "id": @schema.RuntimeValue::Text("exp-1"),
    "amount": @schema.RuntimeValue::Integer(1200),
    "reason": @schema.RuntimeValue::Text("hotel"),
    "applicant": @schema.RuntimeValue::Text("user-1"),
  }
}

///|
fn actor_for_role(role : String) -> @schema.RuntimeActor {
  if role == "" {
    @schema.RuntimeActor::anonymous()
  } else {
    @schema.RuntimeActor::{
      attributes: { "role": @schema.RuntimeValue::Text(role) },
    }
  }
}

///|
fn manager_actor() -> @schema.RuntimeActor {
  actor_for_role("manager")
}

///|
fn parse_demo_input_json(
  input_json : String,
) -> Map[String, @schema.RuntimeValue] raise {
  if input_json.trim() == "" {
    {}
  } else {
    let json = @json.parse(input_json[:])
    json_to_runtime_value_map(json, "input")
  }
}

///|
fn json_to_runtime_value_map(
  json : Json,
  path : String,
) -> Map[String, @schema.RuntimeValue] raise {
  match json {
    Json::Object(entries) => {
      let values : Map[String, @schema.RuntimeValue] = {}
      for key, value in entries {
        values[key] = json_to_runtime_value(value, "\{path}.\{key}")
      }
      values
    }
    _ =>
      raise @builtin.Failure::Failure(
        "\{path} must be a JSON object with flat scalar values",
      )
  }
}

///|
fn json_to_runtime_value(
  json : Json,
  path : String,
) -> @schema.RuntimeValue raise {
  match json {
    Json::Null => @schema.RuntimeValue::Null
    Json::True => @schema.RuntimeValue::Flag(true)
    Json::False => @schema.RuntimeValue::Flag(false)
    Json::String(text) => @schema.RuntimeValue::Text(text)
    _ => {
      let decoded : Result[Int, Error] = try? @json.from_json(json)
      match decoded {
        Ok(value) => @schema.RuntimeValue::Integer(value)
        Err(_) =>
          raise @builtin.Failure::Failure(
            "\{path} must be null, boolean, string, or integer number",
          )
      }
    }
  }
}
