return {
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        default = { "atcoder_template" },
        providers = {
          atcoder_template = {
            name = "AtCoder Template",
            module = "atcoder_snippet",
            score_offset = 100,
          },
        },
      },
    },
  },
}
