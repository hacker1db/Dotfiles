Require tmux
Require nvim
Require eza

Set Shell zsh
Set FontFamily "JetBrainsMono Nerd Font"
Set FontSize 15
Set Width 1600
Set Height 900
Set Padding 16
Set Theme "TokyoNight"
Set WindowBar Colorful

Hide
Type "tmux -L vhs-demo new-session -s dotfiles 'nvim config/nvim/lua/core/keymaps.lua' \; split-window -h -l 42% 'eza --tree --level=1 --icons --group-directories-first; exec zsh' \; split-window -v 'git --no-pager log --oneline --decorate=no -10; exec zsh' \; select-pane -L"
Enter
Sleep 15s
Type ":NoiceDismiss"
Enter
Type ":lua Snacks.notifier.hide()"
Enter
Sleep 1s
Show

Sleep 1s
Screenshot docs/screenshot.png

Hide
Type ":qa!"
Enter
Sleep 500ms
Type "tmux -L vhs-demo kill-server"
Enter
Sleep 500ms
