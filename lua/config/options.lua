vim.opt.clipboard = "unnamedplus"

vim.g.clipboard = {
  name = "OSC52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
    ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
  },
}
vim.filetype.add({ extension = { xacro = "xml" } })

vim.filetype.add({
  extension = {
    xacro = "xml",
    urdf = "xml",
    sdf = "xml",
  },
})
