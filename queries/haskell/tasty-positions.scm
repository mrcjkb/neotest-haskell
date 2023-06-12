;; NOTE: The tasty runner inclides all queries for hspec, too.

(_
  (exp_name) @func_name
  (#lua-match? @func_name "^.*testGroup")
  (exp_literal (string) @namespace.name)
  (exp_list (_))
) @namespace.definition

;; describe (unqualified)
(_ (_ (exp_apply
  (exp_name (variable) @func_name)
  (exp_literal) @namespace.name
)
(#match? @func_name
  "testSpec"
)
)) @namespace.definition

;; describe (qualified)
(_ (_ (exp_apply
  (exp_name (qualified_variable (variable) @func_name))
  (exp_literal) @namespace.name
)
(#match? @func_name
  "testSpec"
)
)) @namespace.definition

;; smallcheck/quickcheck/hedgehog (qualified or unqualified)
(
(exp_apply
  (exp_name) @func_name
  (exp_literal) @test.name
) @test.definition
(#lua-match? @func_name "^.*testProperty.*")
)

;; expectFail (qualified or unqualified)
(
(exp_name) @func_name
(exp_apply
  (exp_name)
  (exp_literal) @test.name
) @test.definition
(#lua-match? @func_name "^.*expectFail")
)

;; HUnit (qualified or unqualified)
(_
  (exp_apply
    (exp_name) @func_name
    (#lua-match? @func_name "^.*testCase")
    (exp_literal) @test.name
  ) @test.definition
)

;; Program (qualified or unqualified)
(_
  (exp_apply
    (exp_name) @func_name
    (#lua-match? @func_name "^.*testProgram")
    (exp_literal) @test.name
  ) @test.definition
)

;; Wai (qualified or unqualified)
(_
  (exp_apply
    (exp_name) @func_name
    (#lua-match? @func_name "^.*testWai")
    (exp_literal) @test.name
  ) @test.definition
)

;; tasty-golden goldenVsFile (qualified or unqualified)
(_
  (exp_apply
    (exp_name) @func_name
    (#lua-match? @func_name "^.*goldenVsFile")
    (exp_literal) @test.name
  ) @test.definition
)
;; tasty-golden goldenVsFileDiff (qualified or unqualified)
(_
  (exp_apply
    (exp_name) @func_name
    (#lua-match? @func_name "^.*goldenVsFileDiff")
    (exp_literal) @test.name
  ) @test.definition
)
;; tasty-golden goldenVsString (qualified or unqualified)
(_
  (exp_apply
    (exp_name) @func_name
    (#lua-match? @func_name "^.*goldenVsString")
    (exp_literal) @test.name
  ) @test.definition
)
;; tasty-golden goldenVsStringDiff (qualified or unqualified)
(_
  (exp_apply
    (exp_name) @func_name
    (#lua-match? @func_name "^.*goldenVsStringDiff")
    (exp_literal) @test.name
  ) @test.definition
)
;; tasty-golden postCleanup (qualified or unqualified)
(_
  (exp_apply
    (exp_name) @func_name
    (#lua-match? @func_name "^.*postCleanup")
    (exp_literal) @test.name
  ) @test.definition
)
