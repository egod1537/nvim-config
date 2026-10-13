-- C++ 개발 환경: clangd LSP + 빠른 컴파일/실행 키맵
local cxx = vim.env.NVIM_CXX
if not cxx or cxx == "" then
  cxx = "g++"
end

return {
  -- 단일 파일 컴파일 & 실행 (PS용)
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>r", group = "run", icon = "▶" },
      },
    },
  },

  -- 키맵: 컴파일 및 실행
  {
    "folke/which-key.nvim",
    keys = {
      {
        "<leader>rb",
        function()
          local file = vim.fn.expand("%:p")
          local out = vim.fn.expand("%:p:r") .. ".exe"
          vim.cmd("w")
          vim.cmd(
            "terminal "
              .. vim.fn.shellescape(cxx)
              .. ' -std=c++17 -O2 -Wall -Wextra -DLOCAL -o "'
              .. out
              .. '" "'
              .. file
              .. '" && echo [Build OK] || echo [Build FAILED]'
          )
        end,
        desc = "Build C++ (g++)",
        ft = "cpp",
      },
      {
        "<leader>rr",
        function()
          local file = vim.fn.expand("%:p")
          local out = vim.fn.expand("%:p:r") .. ".exe"
          vim.cmd("w")
          vim.cmd(
            "terminal "
              .. vim.fn.shellescape(cxx)
              .. ' -std=c++17 -O2 -Wall -DLOCAL -o "'
              .. out
              .. '" "'
              .. file
              .. '" && "'
              .. out
              .. '"'
          )
        end,
        desc = "Build & Run C++",
        ft = "cpp",
      },
    },
  },
}
