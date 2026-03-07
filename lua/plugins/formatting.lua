return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      ["*"] = { "trim_whitespace" },
      python = { "ruff_format" },
      lua = { "stylua" },
      go = { "gofmt" },
      rust = { "rustfmt" },
    },
    formatters = {
      stylua = {
        prepend_args = { "--indent-type", "Spaces", "--indent-width", "2" },
      },
    },
  },
}
