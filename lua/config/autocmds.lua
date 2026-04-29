vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    if vim.v.event.operator == "y" then
      require("vim.ui.clipboard.osc52").copy("+")(vim.v.event.regcontents)
    end
  end,
})
