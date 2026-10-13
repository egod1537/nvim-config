vim.api.nvim_create_user_command("LspInfo", function()
  vim.cmd("checkhealth vim.lsp")
end, { desc = "Show Neovim LSP health and client info" })

vim.api.nvim_create_user_command("LspRestart", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })

  if #clients == 0 then
    clients = vim.lsp.get_clients()
  end

  vim.lsp.stop_client(clients, true)
  vim.defer_fn(function()
    if vim.api.nvim_buf_is_loaded(bufnr) then
      vim.api.nvim_exec_autocmds("FileType", { buffer = bufnr })
    end
  end, 500)
end, { desc = "Restart LSP clients for the current buffer" })
