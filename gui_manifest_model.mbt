///|
priv struct GuiManifestDoc {
  entities : Array[GuiManifestEntity]
}

///|
priv struct GuiManifestEntity {
  name : String
  label : String
  states : Array[GuiManifestState]
  views : Array[GuiManifestView]
  rules : Array[GuiManifestRule]
}

///|
priv struct GuiManifestState {
  name : String
  label : String
}

///|
priv struct GuiManifestView {
  name : String
  fields : Array[GuiManifestField]
  actions : Array[GuiManifestAction]
}

///|
priv struct GuiManifestField {
  name : String
  component : String
  mode : String
}

///|
priv struct GuiManifestAction {
  name : String
  to : String
  inputs : Array[GuiManifestActionInput]
  enabled_when : String?
  role : String?
}

///|
priv struct GuiManifestActionInput {
  name : String
  kind : String
  component : String
  required : Bool
}

///|
priv struct GuiManifestRule {
  name : String
  when_expr : String
}
