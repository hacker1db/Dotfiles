#### COLOUR
# $default or default = no bg color
# colour240 is a black/gray color

tm_color_active=colour32
tm_color_inactive=colour241
tm_color_feature=colour255
tm_color_music=colour255
tm_active_border_color=colour141
tm_clock_color=colour32
tm_icon_color=colour141

black=colour16
white=colour255
gray=colour236
dark_gray=colour236
tm_color_cpu=colour215


# separators
tm_icon="#[fg=$tm_icon_color]$tm_separator_right_thin"
tm_separator_left_bold="◀"
tm_separatr_left_thin="❮"
tm_separator_right_bold="▶"
tm_separator_right_thin="❯"

set -g status-left-length 1001
set -g status-right-length 1000
set -g status-interval 3

# default statusbar colors
set-option -g status-style fg=$tm_color_active,bg=default,default

# default window title colors
set-window-option -g window-status-style fg=$tm_color_inactive,bg=default
set -g window-status-format "#I #W"

# active window title colors
set-window-option -g window-status-current-style fg=$tm_color_active,bg=default
set-window-option -g  window-status-current-format " #[bold]#I #W "

# pane border
set-option -g pane-border-style fg=$tm_color_inactive
set-option -g pane-active-border-style fg=$tm_active_border_color

# message text
set-option -g message-style bg=default,fg=$tm_color_active

# pane number display
set-option -g display-panes-active-colour $tm_color_active
set-option -g display-panes-colour $tm_color_inactive

# clock
set-window-option -g clock-mode-colour $tm_clock_color

tm_tunes="#(osascript -l JavaScript $DOTFILES/applescripts/tunes.js)"
tm_tunes_display="#[bg=${thm_bg}]#[fg=$thm_pink]#[bg=$thm_pink]#[fg=$thm_bg] #[bg=$thm_gray]#[fg=$thm_fg] ${tm_tunes}"
tm_battery="#[fg=$thm_blue]#[fg=$thm_blue]#[fg=$thm_bg,bg=$thm_blue]󰁹#[bg=$thm_gray]#[fg=$thm_fg]#{battery_status_bg} #{battery_percentage} #{battery_remain}"
tm_session_name="#[fg=$tm_color_feature,bold]#S"
tm_git='#[fg=$thm_fg]#[fg=$thm_bk,bg=$thm_blue] #[bg=$thm_gray]#[fg=$thm_fg] #(gitmux -cfg $HOME/.dotfiles/config/tmux/gitmux.conf "#{pane_current_path}")'
tm_clock="#[fg=$thm_cyan]#[fg=$thm_fg]#[fg=$thm_bg,bg=$thm_cyan] #[bg=$thm_gray]#[fg=$thm_fg] %a %h-%d %H:%M"

## Configure status bars
set -g status-left " $tm_session_name $tm_git$tm_icon"
set -g status-right "$tm_tunes_display $tm_icon $tm_clock $tm_icon $tm_battery"
