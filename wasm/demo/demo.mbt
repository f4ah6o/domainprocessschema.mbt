///|
priv struct DemoPreview {
  record : @schema.RuntimeRecord
  actor : @schema.RuntimeActor
}

///|
pub fn render_manifest_preview(yaml : String) -> Result[String, Error] {
  try @schema.compile_gui_html_from_yaml(yaml) catch {
    err => Err(err)
  } noraise {
    html => Ok(html)
  }
}

///|
pub fn render_runtime_preview(
  yaml : String,
  scenario : String,
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
    "submitted-manager" => Ok(DemoPreview::{ record: submitted, actor: manager })
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
fn manager_actor() -> @schema.RuntimeActor {
  @schema.RuntimeActor::{
    attributes: { "role": @schema.RuntimeValue::Text("manager") },
  }
}
