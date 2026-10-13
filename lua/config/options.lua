-- CP 친화 옵션 (LazyVim 기본값 위에 덮어쓰기)
local opt = vim.opt

vim.g.autoformat = true

opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.clipboard = "unnamedplus"

-- C/C++ 파일을 열 때 자동 설정
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp" },
  callback = function()
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
    vim.bo.expandtab = true
    vim.bo.commentstring = "// %s"
  end,
})
