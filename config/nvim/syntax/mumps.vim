if exists("b:current_syntax")
  finish
endif

syntax case ignore

syntax match   mumpsComment    ";.*$"
syntax region  mumpsString     start=/"/ skip=/""/ end=/"/
syntax match   mumpsNumber     "\<\d\+\(\.\d\+\)\?\>"
syntax match   mumpsLabel      "^%\?\a\w*\>"
syntax match   mumpsGlobal     "\^%\?\a\w*"
syntax match   mumpsSpecialVar "\$\a\+\>"
syntax match   mumpsZCommand   "\<z\a*\>"
syntax match   mumpsOperator   "[+\-*/\\#'_?<>=\[\]!&]"

syntax keyword mumpsCommand
  \ break b close c do d else e for f goto g halt h hang
  \ if i job j kill k lock l merge m new n open o quit q read r
  \ set s tcommit trollback tstart ts use u view v write w xecute x

highlight link mumpsComment    Comment
highlight link mumpsString     String
highlight link mumpsNumber     Number
highlight link mumpsLabel      Function
highlight link mumpsGlobal     PreProc
highlight link mumpsSpecialVar Identifier
highlight link mumpsZCommand   Statement
highlight link mumpsOperator   Operator
highlight link mumpsCommand    Statement

let b:current_syntax = "mumps"
