-- LazyVim startup diagnostic — launched via: nvim -S /tmp/nvim-debug.lua
-- Waits for deferred plugin loading, then dumps state to /tmp/nvim-debug-output.txt
vim.defer_fn(function()
  local lines = {}
  table.insert(lines, "COLORSCHEME: " .. (vim.g.colors_name or "NONE"))
  table.insert(lines, "TERMGUICOLORS: " .. tostring(vim.o.termguicolors))

  local lok, lazy = pcall(require, "lazy")
  if lok then
    for _, p in ipairs(lazy.plugins()) do
      local status = p._.loaded and "LOADED" or "not-loaded"
      local err = p._.has_errors and " [ERROR]" or ""
      table.insert(lines, string.format("  %-35s %s%s", p.name, status, err))
    end
  end

  -- LazyVim routes errors through snacks notifications
  local sok, snacks = pcall(require, "snacks")
  if sok and snacks.notifier then
    for _, n in ipairs(snacks.notifier.get_history()) do
      if n.level == "error" or n.level == vim.log.levels.ERROR then
        table.insert(lines, "[ERROR] " .. tostring(n.msg))
      end
    end
  end

  local f = io.open("/tmp/nvim-debug-output.txt", "w")
  f:write(table.concat(lines, "\n") .. "\n")
  f:close()
  vim.cmd("qa!")
end, 5000)
