;; describe
(_ (_ (expression/apply
  function: [
    (variable) @_func_name
    (qualified id: (variable) @_func_name)
  ]
  argument: (expression/literal) @namespace.name)
  (#any-of? @_func_name
    "describe"
    "xdescribe"
    "context"
    "xcontext"
  ))) @namespace.definition

;; test
((expression/apply
  function: [
    (variable) @_func_name
    (qualified id: (variable) @_func_name)
  ]
  argument: (expression/literal) @test.name)
  (#any-of? @_func_name
    "it"
    "xit"
    "prop"
    "xprop"
    "specify"
    "xspecify")) @test.definition

;; test
(_ (expression/apply
  function: [
    (variable) @_func_name
    (qualified id: (variable) @_func_name)
  ]
  argument: (expression/literal) @test.name)
  (#any-of? @_func_name
    "it"
    "xit"
    "prop"
    "xprop"
    "specify"
    "xspecify")) @test.definition
