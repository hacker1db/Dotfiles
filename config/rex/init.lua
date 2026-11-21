-- Rex config migrated from tmux (~/.config/tmux/tmux.conf) and Ghostty.
--
-- tmux runs inside Rex, and both use ctrl+a as the prefix. So ctrl+a and
-- ctrl+h/j/k/l are Lua functions that check the focused terminal's foreground
-- program: when it is tmux they return false and the key goes to tmux;
-- otherwise Rex handles them with the same bindings tmux has.

local terminal = "com.superlogical.terminal"

-- Name of the focused terminal's foreground program, or nil.
local function foreground()
  local p = rex.block.call(terminal, "process", {})
  return p and p.foreground and p.foreground.name or nil
end

local function in_tmux()
  return foreground() == "tmux"
end

-- Same programs vim-tmux-navigator hands the key to (vim, nvim, view, fzf).
local function wants_nav_keys(name)
  if not name then return false end
  name = name:lower()
  return name:match("^g?%.?view$") ~= nil
      or name:match("^l?n?vim?x?$") ~= nil
      or name:match("^fzf$") ~= nil
      or name:match("^l?n?vim?x?diff$") ~= nil
end

-- Prefix: ctrl+a enters the one-key "prefix" mode, unless tmux is in front.
rex.mode("prefix", { exclusive = true })
rex.bind("ctrl+a", function(ctx, ev)
  if in_tmux() then return false end
  rex.client.queue("client.mode.enter", { name = "prefix", once = true })
  return true
end)

-- tmux.conf:23 bind-key a send-prefix
rex.bind("prefix/a", "pane.send_key", { key = "ctrl+a" })
-- tmux.conf:39 bind = select-layout tiled
rex.bind("prefix/=", "pane.balance")
-- tmux.conf:58 bind r source-file ...
rex.bind("prefix/r", "client.config.reload")
-- tmux.conf:60 bind-key x kill-pane
rex.bind("prefix/x", "pane.close")
-- tmux.conf:63 bind N new-window
rex.bind("prefix/shift+n", "client.tab.new")
-- tmux.conf:66-68 splits
rex.bind("prefix/\\", "pane.split", { direction = "right" })
rex.bind("prefix/shift+\\", "pane.split", { direction = "right" })
rex.bind("prefix/-", "pane.split", { direction = "down" })
-- tmux.conf:74-77 pane focus
rex.bind("prefix/h", "pane.focus", { direction = "left" })
rex.bind("prefix/j", "pane.focus", { direction = "down" })
rex.bind("prefix/k", "pane.focus", { direction = "up" })
rex.bind("prefix/l", "pane.focus", { direction = "right" })
-- tmux.conf:83-88 resize / zoom (bind -r)
rex.bind("prefix/shift+h", "pane.resize", { amount = 10, direction = "left" })
rex.bind("prefix/shift+j", "pane.resize", { amount = 10, direction = "down" })
rex.bind("prefix/shift+k", "pane.resize", { amount = 10, direction = "up" })
rex.bind("prefix/shift+l", "pane.resize", { amount = 10, direction = "right" })
rex.bind("prefix/shift+m", "pane.zoom")
-- tmux.conf:118 bind Up new-window ... (swap-pane/select-window not migrated)
rex.bind("prefix/up", "client.tab.new")

-- Repeat mode for tmux `bind -r` bindings: ctrl+a ctrl+r enters, enter/escape leaves.
rex.mode("repeat", { exclusive = true })
rex.bind("prefix/ctrl+r", "client.mode.enter", { name = "repeat" })
rex.bind("repeat/enter", "client.mode.exit")
rex.bind("repeat/escape", "client.mode.exit")
rex.bind("repeat/shift+h", "pane.resize", { amount = 10, direction = "left" })
rex.bind("repeat/shift+j", "pane.resize", { amount = 10, direction = "down" })
rex.bind("repeat/shift+k", "pane.resize", { amount = 10, direction = "up" })
rex.bind("repeat/shift+l", "pane.resize", { amount = 10, direction = "right" })
rex.bind("repeat/shift+m", "pane.zoom")

-- ctrl+h/j/k/l move between panes everywhere (vim-tmux-navigator style).
-- In tmux, vim-tmux-navigator handles the key; in vim/nvim/fzf the program
-- keeps it; otherwise Rex moves focus between its own panes.
for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
  rex.bind("ctrl+" .. key, function(ctx, ev)
    local name = foreground()
    if name == "tmux" or wants_nav_keys(name) then return false end
    rex.client.queue("pane.focus", { direction = direction })
    return true
  end)
end
