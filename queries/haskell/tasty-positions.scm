;; NOTE: The tasty runner includes all queries for hspec, too.

(_ 
  function: (expression/apply
    function: [
      (variable) @_func_name
      (qualified id: (variable) @_func_name)
    ]
    (#lua-match? @_func_name "^.*testGroup")
    argument: (literal) @namespace.name)
 argument: (list)) @namespace.definition

;; testSpec
(_ (_ (expression/apply
  function: [
    (variable) @_func_name
    (qualified id: (variable) @_func_name)
  ]
  argument: (expression/literal) @namespace.name)
  (#match? @_func_name "testSpec"))) @namespace.definition

;; smallcheck/quickcheck/hedgehog
((_ (expression/apply
  function: [
    (variable) @_func_name
    (qualified id: (variable) @_func_name)
  ]
  argument: (expression/literal) @test.name)) @test.definition
  (#lua-match? @_func_name "^.*testProperty.*"))

;; expectFail
((variable) @_func_name
(expression/apply
  argument: [
    (variable) @test.name
    (qualified id: (variable) @test.name)
  ]
) @test.definition
(#lua-match? @_func_name "^.*expectFail"))

;; HUnit
((_ (expression/apply
  function: [
    (variable) @_func_name
    (qualified id: (variable) @_func_name)
  ]
  argument: (expression/literal) @test.name)
  (#lua-match? @_func_name "^.*testCase")
  ) @test.definition)

;; Program (qualified or unqualified)
((_ (_ (_ (expression/apply
  function: [
    (variable) @_func_name
    (qualified id: (variable) @_func_name)
  ]
  argument: (expression/literal) @test.name)
  (#lua-match? @_func_name "^.*testProgram")
  ))) @test.definition)


;; Wai
((_ (expression/apply
  function: (expression/apply
    function: [
      (variable) @_func_name
      (qualified id: (variable) @_func_name)
    ]
    (#lua-match? @_func_name "^.*testWai"))
  argument: (expression/literal) @test.name)) @test.definition)

;; tasty-golden
((_ (_ (_ (expression/apply
  function: [
    (variable) @_func_name
    (qualified id: (variable) @_func_name)
  ]
  argument: (expression/literal) @test.name)
  (#any-of? @_func_name
    "goldenVsFile"
    "goldenVsStringDiff"
    "postCleanup")))) @test.definition)

;; tasty-golden
((_ (_ (expression/apply
  function: [
    (variable) @_func_name
    (qualified id: (variable) @_func_name)
  ]
  argument: (expression/literal) @test.name)
  (#any-of? @_func_name
    "goldenVsString"))) @test.definition)

;; tasty-golden
((_ (_ (_ (_ (expression/apply
  function: [
    (variable) @_func_name
    (qualified id: (variable) @_func_name)
  ]
  argument: (expression/literal) @test.name)
  (#any-of? @_func_name
    "goldenVsFileDiff"))))) @test.definition)
