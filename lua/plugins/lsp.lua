local clangd = vim.env.NVIM_CLANGD_PATH
if not clangd or clangd == "" then
  clangd = "clangd"
end

local cxx = vim.env.NVIM_CXX
if not cxx or cxx == "" then
  cxx = vim.fn.exepath("g++")
  if cxx == "" then
    cxx = "g++"
  end
end

return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      tsgo = {
        mason = false,
        cmd = function(dispatchers, config)
          -- TypeScript 7 ships its native language server through the tsc entry point.
          local tsc = vim.fs.joinpath(config.root_dir, "node_modules", "typescript", "bin", "tsc")
          return vim.lsp.rpc.start({ "node", tsc, "--lsp", "--stdio" }, dispatchers)
        end,
      },
      clangd = {
        cmd = {
          clangd,
          "--background-index",
          "--clang-tidy",
          "--header-insertion=iwyu",
          "--completion-style=detailed",
          "--query-driver=" .. cxx,
        },
      },
    },
  },
}
