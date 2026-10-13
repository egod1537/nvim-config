-- C development: Treesitter, clangd project detection, and build/run shortcuts.
local function current_c_paths()
  vim.cmd("write")
  local source = vim.fn.expand("%:p")
  return source, vim.fn.expand("%:p:r") .. ".exe"
end

local function open_terminal(command)
  vim.cmd("botright 12split")
  vim.fn.termopen(command)
  vim.cmd("startinsert")
end

local function build_c(run_after_build)
  local source, output = current_c_paths()
  local compiler = "gcc"
  local build = table.concat({
    vim.fn.shellescape(compiler),
    "-std=c17",
    "-g",
    "-Wall",
    "-Wextra",
    "-Wpedantic",
    vim.fn.shellescape(source),
    "-o",
    vim.fn.shellescape(output),
  }, " ")

  if run_after_build then
    open_terminal(build .. " && " .. vim.fn.shellescape(output))
  else
    open_terminal(build .. " && echo [Build OK]")
  end
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "c" } },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          root_markers = {
            ".clangd",
            ".clang-format",
            "compile_commands.json",
            "compile_flags.txt",
            "CMakeLists.txt",
            ".git",
          },
        },
      },
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>r", group = "run", icon = "▶" },
      },
    },
    keys = {
      {
        "<leader>rb",
        function()
          build_c(false)
        end,
        desc = "Build C (gcc)",
        ft = "c",
      },
      {
        "<leader>rr",
        function()
          build_c(true)
        end,
        desc = "Build & Run C",
        ft = "c",
      },
    },
  },
}
