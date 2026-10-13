local function windows_safe_name(name)
  name = name:gsub('[<>:"/\\|?*%c]', "_")
  name = name:gsub("[%. ]+$", "")

  if name == "" then
    return "problem"
  end

  local basename = (name:match("^([^%.]+)") or ""):upper()
  if basename:match("^CON$")
    or basename:match("^PRN$")
    or basename:match("^AUX$")
    or basename:match("^NUL$")
    or basename:match("^COM[1-9]$")
    or basename:match("^LPT[1-9]$")
  then
    name = "_" .. name
  end

  return name
end

local cxx = vim.env.NVIM_CXX
if not cxx or cxx == "" then
  cxx = "g++"
end

return {
  "xeluxee/competitest.nvim",
  lazy = false,
  dependencies = { "MunifTanjim/nui.nvim" },

  keys = {
    { "<leader>rt", "<cmd>CompetiTest run<cr>", desc = "Run testcases", ft = { "c", "cpp" } },
    { "<leader>ra", "<cmd>CompetiTest add_testcase<cr>", desc = "Add testcase", ft = { "c", "cpp" } },
    { "<leader>re", "<cmd>CompetiTest edit_testcase<cr>", desc = "Edit testcase", ft = { "c", "cpp" } },
    { "<leader>rs", "<cmd>CompetiTest show_ui<cr>", desc = "Show testcase results", ft = { "c", "cpp" } },
  },

  config = function()
    require("competitest").setup({
      start_receiving_persistently_on_setup = true,

      open_received_problems = true,
      open_received_contests = true,

      received_problems_path = function(task, file_extension)
        local problem = windows_safe_name(task.name)
        return string.format("%s/%s/%s.%s", vim.fn.getcwd(), problem, problem, file_extension)
      end,
      received_problems_prompt_path = false,
      received_contests_problems_path = function(task, file_extension)
        local problem = windows_safe_name(task.name)
        return string.format("%s/%s.%s", problem, problem, file_extension)
      end,

      template_file = {
        cpp = vim.fn.stdpath("config") .. "/templates/cp_template.cpp",
      },

      compile_command = {
        cpp = {
          exec = cxx,
          args = {
            "-std=gnu++20",
            "-O2",
            "-Wall",
            "-Wextra",
            "$(FNAME)",
            "-o",
            "$(FNOEXT).exe",
          },
        },
      },

      run_command = {
        cpp = {
          exec = ".\\$(FNOEXT).exe",
        },
      },

      testcases_use_single_file = false,
      testcases_input_file_format = "$(FNOEXT)_input$(TCNUM).txt",
      testcases_output_file_format = "$(FNOEXT)_output$(TCNUM).txt",
    })
  end,
}
