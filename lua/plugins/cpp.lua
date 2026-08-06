local function find_executable(environment_variable, command)
  local configured = vim.env[environment_variable]
  if configured and configured ~= "" then
    return vim.fs.normalize(configured)
  end

  local detected = vim.fn.exepath(command)
  if detected ~= "" then
    return vim.fs.normalize(detected)
  end
end

local clangd = find_executable("NVIM_CLANGD_PATH", "clangd")
local cxx = find_executable("NVIM_CXX", "g++")
local clangd_options = {}

-- PATH에서 clangd를 찾으면 시스템 설치본을 사용하고, 찾지 못하면
-- LazyVim/Mason의 기본 clangd 설치 및 설정에 맡긴다.
if clangd then
  clangd_options.cmd = { clangd }
  clangd_options.mason = false
  if cxx then
    table.insert(clangd_options.cmd, "--query-driver=" .. cxx)
  end
end

return {
  { import = "lazyvim.plugins.extras.lang.clangd" },

  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "clang-format",
        "codelldb",
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = clangd_options,
      },
    },
  },
}
