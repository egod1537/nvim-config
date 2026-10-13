-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("user_cpp_format_on_save", { clear = true }),
  pattern = { "*.c", "*.cc", "*.cpp", "*.cxx", "*.h", "*.hh", "*.hpp", "*.hxx", "*.ipp", "*.ixx" },
  callback = function(event)
    if vim.g.autoformat == false or vim.b[event.buf].autoformat == false then
      return
    end

    require("conform").format({
      bufnr = event.buf,
      formatters = { "clang-format", "flightui-format" },
      timeout_ms = 3000,
      lsp_format = "never",
    })
  end,
})
