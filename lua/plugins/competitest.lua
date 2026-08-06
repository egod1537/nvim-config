local contest_problem_index = 0
local is_windows = vim.fn.has("win32") == 1
local cxx = vim.env.NVIM_CXX
if not cxx or cxx == "" then
  cxx = "g++"
end

local ps_root = vim.env.NVIM_PS_ROOT
if not ps_root or ps_root == "" then
  ps_root = vim.fs.joinpath(vim.fn.expand("~"), "proj", "ps")
end
ps_root = vim.fs.normalize(ps_root):lower()

local function contest_problem_label(index)
  local label = ""
  repeat
    label = string.char(65 + (index % 26)) .. label
    index = math.floor(index / 26) - 1
  until index < 0
  return label
end

return {
  {
    "xeluxee/competitest.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    cmd = "CompetiTest",
    init = function()
      local group = vim.api.nvim_create_augroup("competitest_auto_receive_ps", { clear = true })

      vim.api.nvim_create_autocmd("VimEnter", {
        group = group,
        once = true,
        callback = function()
          if vim.fs.normalize(vim.fn.getcwd()):lower() ~= ps_root then
            return
          end

          local uv = vim.uv or vim.loop
          local lock_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "competitest-ps-27121.lock")
          local owns_lock = false
          local exiting = false
          local timer = uv.new_timer()
          local checking_port = false

          local function release_lock()
            exiting = true
            if timer and not timer:is_closing() then
              timer:stop()
              timer:close()
            end
            if owns_lock then
              uv.fs_rmdir(lock_dir)
              owns_lock = false
            end
          end

          local function try_acquire_lock()
            if owns_lock or exiting then
              return
            end

            local created, err = uv.fs_mkdir(lock_dir, 448)
            if created then
              owns_lock = true
              local now = os.time()
              uv.fs_utime(lock_dir, now, now)
              return
            end

            -- A killed Neovim can leave its lock behind. A live owner refreshes it
            -- every second, so an unchanged lock older than five seconds is stale.
            if err and err:match("EEXIST") then
              local stat = uv.fs_stat(lock_dir)
              if stat and os.time() - stat.mtime.sec > 5 then
                uv.fs_rmdir(lock_dir)
              end
            end
          end

          local function ensure_listener()
            if not owns_lock or exiting or checking_port then
              return
            end

            checking_port = true
            local probe = uv.new_tcp()
            if not probe then
              checking_port = false
              return
            end

            local bound = probe:bind("127.0.0.1", 27121)
            local listening = bound and probe:listen(1, function() end)
            local port_available = not not listening
            probe:close(vim.schedule_wrap(function()
              checking_port = false
              if port_available and owns_lock and not exiting then
                vim.cmd("CompetiTest receive persistently")
              end
            end))
          end

          vim.api.nvim_create_autocmd("VimLeavePre", {
            group = group,
            once = true,
            callback = release_lock,
          })

          try_acquire_lock()
          ensure_listener()
          if timer then
            timer:start(
              1000,
              1000,
              vim.schedule_wrap(function()
                if exiting then
                  return
                end
                if owns_lock then
                  local now = os.time()
                  local refreshed = uv.fs_utime(lock_dir, now, now)
                  if not refreshed then
                    owns_lock = false
                  end
                else
                  try_acquire_lock()
                end
                ensure_listener()
              end)
            )
          end
        end,
      })
    end,
    keys = {
      { "<leader>tr", "<cmd>CompetiTest run<cr>", desc = "Run testcases" },
      { "<leader>ta", "<cmd>CompetiTest add_testcase<cr>", desc = "Add testcase" },
      { "<leader>te", "<cmd>CompetiTest edit_testcase<cr>", desc = "Edit testcase" },
      { "<leader>td", "<cmd>CompetiTest delete_testcase<cr>", desc = "Delete testcase" },
      { "<leader>tp", "<cmd>CompetiTest receive problem<cr>", desc = "Receive problem" },
      { "<leader>tc", "<cmd>CompetiTest receive contest<cr>", desc = "Receive contest" },
    },
    opts = {
      compile_command = {
        cpp = {
          exec = cxx,
          args = {
            "-std=c++20",
            "-Wall",
            "-Wextra",
            "-O2",
            "$(FNAME)",
            "-o",
            "$(FNOEXT)" .. (is_windows and ".exe" or ""),
          },
        },
      },
      run_command = {
        cpp = { exec = (is_windows and ".\\" or "./") .. "$(FNOEXT)" .. (is_windows and ".exe" or "") },
      },
      maximum_time = 5000,
      output_compare_method = "squish",
      testcases_auto_detect_storage = true,
      received_problems_path = "$(CWD)/$(PROBLEM)/$(PROBLEM).$(FEXT)",
      received_problems_prompt_path = false,
      received_contests_directory = function(task)
        contest_problem_index = 0

        local separator = task.group:find(" - ", 1, true)
        local contest_name = separator and task.group:sub(separator + 3) or task.group
        contest_name = contest_name:gsub('[<>:"/\\|?*]', "_"):gsub("[%.%s]+$", "")
        if contest_name == "" then
          contest_name = "contest"
        end

        return vim.fs.joinpath(vim.fn.getcwd(), contest_name)
      end,
      received_contests_problems_path = function(_, file_extension)
        local label = contest_problem_label(contest_problem_index)
        contest_problem_index = contest_problem_index + 1
        return vim.fs.joinpath(label, label .. "." .. file_extension)
      end,
      received_contests_prompt_directory = false,
      received_contests_prompt_extension = false,
    },
  },
}
