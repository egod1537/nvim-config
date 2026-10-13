return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        c = { "clang-format" },
        cpp = { "clang-format", "flightui-format" },
      },
      formatters = {
        ["flightui-format"] = {
          command = "python",
          args = { vim.fn.stdpath("config") .. "/scripts/flightui_format.py" },
          stdin = true,
        },
      },
    },
  },
}
