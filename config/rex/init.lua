-- Rex config migrated from tmux (~/.config/tmux/tmux.conf) and Ghostty.
-- Prefix ctrl+a becomes the first key of each sequence.

-- tmux.conf:23 bind-key a send-prefix
rex.bind("ctrl+a>a", "pane.send_key", { key = "ctrl+a" })

-- tmux.conf:39 bind = select-layout tiled
rex.bind("ctrl+a>=", "pane.balance")

-- tmux.conf:58 bind r source-file ...
rex.bind("ctrl+a>r", "client.config.reload")

-- tmux.conf:60 bind-key x kill-pane
rex.bind("ctrl+a>x", "pane.close")

-- tmux.conf:63 bind N new-window
rex.bind("ctrl+a>shift+n", "client.tab.new")

-- tmux.conf:66-68 splits
rex.bind("ctrl+a>\\", "pane.split", { direction = "right" })
rex.bind("ctrl+a>shift+\\", "pane.split", { direction = "right" })
rex.bind("ctrl+a>-", "pane.split", { direction = "down" })

-- tmux.conf:74-77 pane focus
rex.bind("ctrl+a>h", "pane.focus", { direction = "left" })
rex.bind("ctrl+a>j", "pane.focus", { direction = "down" })
rex.bind("ctrl+a>k", "pane.focus", { direction = "up" })
rex.bind("ctrl+a>l", "pane.focus", { direction = "right" })

-- tmux.conf:83-88 resize / zoom (bind -r)
rex.bind("ctrl+a>shift+h", "pane.resize", { amount = 10, direction = "left" })
rex.bind("ctrl+a>shift+j", "pane.resize", { amount = 10, direction = "down" })
rex.bind("ctrl+a>shift+k", "pane.resize", { amount = 10, direction = "up" })
rex.bind("ctrl+a>shift+l", "pane.resize", { amount = 10, direction = "right" })
rex.bind("ctrl+a>shift+m", "pane.zoom")

-- tmux.conf:118 bind Up new-window ... (swap-pane/select-window not migrated)
rex.bind("ctrl+a>up", "client.tab.new")

-- Repeat mode for tmux `bind -r` bindings: ctrl+a ctrl+r enters, enter/escape leaves.
rex.mode("repeat", { exclusive = true })
rex.bind("ctrl+a>ctrl+r", "client.mode.enter", { name = "repeat" })
rex.bind("repeat/enter", "client.mode.exit")
rex.bind("repeat/escape", "client.mode.exit")
rex.bind("repeat/shift+h", "pane.resize", { amount = 10, direction = "left" })
rex.bind("repeat/shift+j", "pane.resize", { amount = 10, direction = "down" })
rex.bind("repeat/shift+k", "pane.resize", { amount = 10, direction = "up" })
rex.bind("repeat/shift+l", "pane.resize", { amount = 10, direction = "right" })
rex.bind("repeat/shift+m", "pane.zoom")
