_G.ElixirIndent = function()
  local lnum = vim.v.lnum
  local prev_lnum = vim.fn.prevnonblank(lnum - 1)
  local prev_line = vim.fn.getline(prev_lnum)
  local prev_indent = vim.fn.indent(prev_lnum)

  if prev_line:match("->%s*$") then
    return prev_indent + vim.fn.shiftwidth()
  end

  return require("nvim-treesitter.indent").get_indent(lnum)
end

vim.bo.indentexpr = "v:lua.ElixirIndent()"
