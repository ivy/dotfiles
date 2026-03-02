-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

require("which-key").add({ { "<leader>y", group = "yank" } })

local function yank_path(expr, label)
  local path = vim.fn.expand(expr)

  if path == "" then
    vim.notify("No file path (buffer not associated with a file)", vim.log.levels.WARN)
    return
  end

  pcall(vim.fn.setreg, "+", path)
  vim.fn.setreg('"', path)

  vim.notify(("Yanked %s: %s"):format(label, path), vim.log.levels.INFO)
end

vim.keymap.set("n", "<leader>yp", function()
  yank_path("%:.", "relative path")
end, { desc = "Yank relative file path" })

vim.keymap.set("n", "<leader>yP", function()
  yank_path("%:p", "absolute path")
end, { desc = "Yank absolute file path" })

vim.keymap.set("n", "<leader>yn", function()
  yank_path("%:t", "filename")
end, { desc = "Yank filename" })
