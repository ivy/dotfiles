-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Sync vim.o.background with system appearance (dark/light).
-- Runs at startup and on FocusGained so tmux set-environment BG changes
-- propagate into running Neovim instances automatically.
--
-- Only when there is a real signal: macOS, or BG set in the environment or
-- tmux. Without one the appearance script falls back to "light", which would
-- clobber the background Neovim already detected from the terminal.
local function has_appearance_signal()
  if vim.fn.has("mac") == 1 or vim.env.BG then
    return true
  end
  return vim.env.TMUX ~= nil and vim.system({ "tmux", "show-environment", "BG" }):wait().code == 0
end

local function sync_background()
  if not has_appearance_signal() then
    return
  end
  local obj = vim.system({ vim.fn.expand("~/.local/libexec/dotfiles/appearance") }, { text = true }):wait()
  if obj.code == 0 then
    local bg = vim.trim(obj.stdout)
    if bg == "dark" or bg == "light" then
      vim.o.background = bg
    end
  end
end

sync_background()

vim.api.nvim_create_autocmd("FocusGained", {
  callback = sync_background,
})

-- Git commit rulers for best practices (50 chars for subject, 72 for body)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "gitcommit",
  callback = function()
    vim.opt_local.colorcolumn = "50,72"
  end,
})
