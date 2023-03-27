;; describe (unqualified)
(_ (_ (exp_apply
  (exp_name (variable) @func_name)
  (exp_literal) @namespace.name
)
(#any-of? @func_name
  "describe"
  "xdescribe"
  "context"
  "xcontext"
)
)) @namespace.definition

;; describe (qualified)
(_ (_ (exp_apply
  (exp_name (qualified_variable (variable) @func_name))
  (exp_literal) @namespace.name
)
(#any-of? @func_name
  "describe"
  "xdescribe"
  "context"
  "xcontext"
)
)) @namespace.definition

;; test (unqualified)
((exp_apply
  (exp_name (variable) @func_name)
  (exp_literal) @test.name
)
(#any-of? @func_name
  "it"
  "xit"
  "prop"
  "xprop"
  "specify"
  "xspecify"
)
) @test.definition

;; test (qualified)
((exp_apply
  (exp_name (qualified_variable (variable) @func_name))
  (exp_literal) @test.name
)
(#any-of? @func_name
  "it"
  "xit"
  "prop"
  "xprop"
  "specify"
  "xspecify"
)
) @test.definition
