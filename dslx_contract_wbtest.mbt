///|
fn dslx_domain_contract_spec() -> @dslx.Dslx {
  @dslx.domn()
}

///|
fn dslx_domain_contract_example() -> @dslx.File {
  @dslx.file(
    "examples/domainprocessschema.dsl",
    "domain ExpenseRequest entity ExpenseRequest process Submit ExpenseRequest\n",
  )
}

///|
fn dslx_domain_contract_project() -> @dslx.Proj {
  @dslx.proj("domainprocessschema-contract")
  .dslx(dslx_domain_contract_spec())
  .file(@dslx.file("README.md", "# domainprocessschema contract\n"))
  .exmp(dslx_domain_contract_example())
}

///|
test "dslx domain contract describes private project" {
  let spec = dslx_domain_contract_spec()
  let project = dslx_domain_contract_project()
  inspect(@dslx.name(spec), content="Domn")
  inspect(@dslx.vspc(spec).length(), content="0")
  inspect(@dslx.vprj(project).length(), content="0")
  let files = @dslx.pack(project)
  inspect(files.length(), content="6")
  inspect(files[0].path, content="README.md")
  inspect(files[1].path, content="examples/domainprocessschema.dsl")
  inspect(files[2].path, content="Domn/astx.mbt")
}

///|
test "dslx domain contract checks examples through project" {
  let project = dslx_domain_contract_project()
  let example = dslx_domain_contract_example()
  let parsed = @dslx.runp(project, "Domn", "domn", example.text)
  inspect(parsed.done, content="true")
  inspect(parsed.digs.length(), content="0")
  inspect(@dslx.chex(project, "Domn", "domn", example).length(), content="0")
}

///|
test "dslx domain contract reports missing spec and invalid example" {
  let project = dslx_domain_contract_project()
  let example = dslx_domain_contract_example()
  let missing = @dslx.runp(project, "Missing", "domn", example.text)
  inspect(missing.done, content="false")
  inspect(missing.tree is None, content="true")
  inspect(missing.digs.length(), content="1")
  inspect(missing.digs[0].text, content="unknown project spec")

  let invalid = @dslx.file("examples/invalid-domainprocessschema.dsl", "domain")
  let invalid_diags = @dslx.chex(project, "Domn", "domn", invalid)
  inspect(invalid_diags.length(), content="1")
  inspect(invalid_diags[0].text, content="expected pattern")
}
