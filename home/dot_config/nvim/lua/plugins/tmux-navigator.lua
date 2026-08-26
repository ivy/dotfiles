-- ctrl+h/j/k/l crosses Neovim splits and the surrounding multiplexer's panes as
-- one motion. vim-tmux-navigator handles that for tmux; under herdr the handoff
-- at the edge of a Neovim split has to be made here, so the keys dispatch on
-- the environment instead of binding the plugin's commands directly.
--
-- The other half of the herdr handoff — deciding whether a keypress belongs to
-- the editor at all — is home/dot_local/libexec/dotfiles/herdr-navigate.
local directions = {
  { key = "<c-h>", wincmd = "h", direction = "left", tmux = "TmuxNavigateLeft" },
  { key = "<c-j>", wincmd = "j", direction = "down", tmux = "TmuxNavigateDown" },
  { key = "<c-k>", wincmd = "k", direction = "up", tmux = "TmuxNavigateUp" },
  { key = "<c-l>", wincmd = "l", direction = "right", tmux = "TmuxNavigateRight" },
}

local function navigate(spec)
  if vim.env.HERDR_ENV ~= "1" then
    vim.cmd(spec.tmux)
    return
  end

  local from = vim.api.nvim_get_current_win()
  vim.cmd.wincmd(spec.wincmd)
  if vim.api.nvim_get_current_win() ~= from then
    return
  end

  -- No Neovim split that way, so the neighbour is herdr's to find. Never route
  -- this through herdr-navigate: that would forward the key straight back.
  local pane = vim.env.HERDR_PANE_ID
  if pane then
    vim.system({ "herdr", "pane", "focus", "--direction", spec.direction, "--pane", pane })
  end
end

local keys = {}
for _, spec in ipairs(directions) do
  table.insert(keys, {
    spec.key,
    function()
      navigate(spec)
    end,
    desc = "Navigate " .. spec.direction,
  })
end
table.insert(keys, { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" })

return {
  "christoomey/vim-tmux-navigator",
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
    "TmuxNavigatePrevious",
  },
  -- Loading the plugin would otherwise reclaim ctrl+h/j/k/l for its own
  -- mappings and drop the herdr branch above.
  init = function()
    vim.g.tmux_navigator_no_mappings = 1
  end,
  keys = keys,
}
