Output docs/demo.gif

Require eza
Require bat
Require nvim

Set Shell zsh
Set FontFamily "JetBrainsMono Nerd Font"
Set FontSize 16
Set Width 1200
Set Height 650
Set Padding 20
Set Theme "TokyoNight"
Set TypingSpeed 60ms
Set WindowBar Colorful

Hide
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
