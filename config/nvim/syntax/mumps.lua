if vim.b.current_syntax then
  return
end

vim.cmd("syntax case ignore")

vim.cmd([[syntax match   mumpsComment    ";.*$"]])
vim.cmd([[syntax region  mumpsString     start=/"/ skip=/""/ end=/"/]])
vim.cmd([[syntax match   mumpsNumber     "\<\d\+\(\.\d\+\)\?\>"]])
vim.cmd([[syntax match   mumpsLabel      "^%\?\a\w*\>"]])
vim.cmd([[syntax match   mumpsGlobal     "\^%\?\a\w*"]])
vim.cmd([[syntax match   mumpsSpecialVar "\$\a\+\>"]])
vim.cmd([[syntax match   mumpsZCommand   "\<z\a*\>"]])
vim.cmd([[syntax match   mumpsOperator   "[+\-*/\\#'_?<>=\[\]!&]"]])

vim.cmd([[
syntax keyword mumpsCommand
  \ break b close c do d else e for f goto g halt h hang
  \ if i job j kill k lock l merge m new n open o quit q read r
  \ set s tcommit trollback tstart ts use u view v write w xecute x
]])

for group, link in pairs({
  mumpsComment    = "Comment",
  mumpsString     = "String",
  mumpsNumber     = "Number",
  mumpsLabel      = "Function",
  mumpsGlobal     = "PreProc",
  mumpsSpecialVar = "Identifier",
  mumpsZCommand   = "Statement",
  mumpsOperator   = "Operator",
  mumpsCommand    = "Statement",
}) do
  vim.api.nvim_set_hl(0, group, { link = link, default = true })
end

vim.b.current_syntax = "mumps"
