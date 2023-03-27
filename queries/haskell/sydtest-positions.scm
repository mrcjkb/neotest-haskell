;; NOTE: The sydtest runner inclides all queries for hspec, too.

;; test (unqualified)
((exp_apply
  (exp_name (variable) @func_name)
  (exp_literal) @test.name
)
(#any-of? @func_name
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
  "xspecifyWithAll"
)
) @test.definition

;; test (qualified)
((exp_apply
  (exp_name (qualified_variable (variable) @func_name))
  (exp_literal) @test.name
)
(#any-of? @func_name
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
  "xspecifyWithAll"
)
) @test.definition
