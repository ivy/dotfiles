return {
  "apple/pkl-neovim",
  lazy = true,
  ft = "pkl",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    build = function(_)
      vim.cmd("TSUpdate")
    end,
    "L3MON4D3/LuaSnip",
  },
  -- The pkl parser is installed via ensure_installed in treesitter.lua; this
  -- plugin is lazy, so :TSInstall does not exist yet when its build runs.
  build = function()
    require("pkl-neovim").init()
  end,
  config = function()
    require("luasnip.loaders.from_snipmate").lazy_load()

    vim.g.pkl_neovim = {
      start_command = { "pkl-lsp" },
    }
  end,
}
