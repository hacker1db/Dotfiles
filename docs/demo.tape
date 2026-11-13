Output docs/demo.gif

Require tmux
Require eza
Require bat
Require nvim

Set Shell zsh
Set FontFamily "JetBrainsMono Nerd Font"
Set FontSize 16
Set Width 1200
Set Height 650
Set Padding 20
Set Theme { "name": "Eldritch", "background": "#212337", "foreground": "#ebfafa", "cursor": "#37f499", "selection": "#bf4f8e", "black": "#21222c", "red": "#f9515d", "green": "#37f499", "yellow": "#e9f941", "blue": "#9071f4", "magenta": "#f265b5", "cyan": "#04d1f9", "white": "#ebfafa", "brightBlack": "#7081d0", "brightRed": "#f16c75", "brightGreen": "#69f8b3", "brightYellow": "#f1fc79", "brightBlue": "#a48cf2", "brightMagenta": "#fd92ce", "brightCyan": "#66e4fd", "brightWhite": "#ffffff" }
Set TypingSpeed 60ms
Set WindowBar Colorful

Hide
Type "tmux -L vhs-demo new-session -s dotfiles"
Enter
Sleep 3s
Type "clear"
Enter
Sleep 1s
Show

Type "eza --tree --level=1 --icons --group-directories-first"
Sleep 300ms
Enter
Sleep 3s

Type "bat --paging=never --line-range 1:20 install.sh"
Sleep 300ms
Enter
Sleep 4s

Type "clear && git log --oneline -8"
Sleep 300ms
Enter
Sleep 3s

Type "nvim config/nvim/lua/core/keymaps.lua"
Sleep 300ms
Enter
Sleep 4s
Type ":q"
Enter
Sleep 1s

Hide
Type "tmux -L vhs-demo kill-server"
Enter
Sleep 500ms
