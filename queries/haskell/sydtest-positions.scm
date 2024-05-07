;; NOTE: The sydtest runner includes all queries for hspec, too.

;; test (unqualified)
((expression/apply
  function: [
    (variable) @_func_name
    (qualified id: (variable) @_func_name)
  ]
  argument: (expression/literal) @test.name)
  (#any-of? @_func_name
    "itWithOuter"
    "xitWithOuter"
    "itWithBoth"
    "xitWithBoth"
    "itWithAll"
    "xitWithAll"
    "specifyWithOuter"
    "xspecifyWithOuter"
    "specifyWithBoth"
    "xspecifyWithBoth"
    "specifyWithAll"
    "xspecifyWithAll")) @test.definition
