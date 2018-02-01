#### COLOUR
# $default or default = no bg color
tm_color_active=colour32
tm_color_inactive=colour241
tm_color_feature=colour255
tm_color_music=colour255
tm_active_border_color=colour240
tm_clock_color=colour240
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

set -g status-left-length 32
set -g status-right-length 150
set -g status-interval 5

# default statusbar colors
set-option -g status-fg $tm_color_active
set-option -g status-bg default
set-option -g status-attr default

# default window title colors
set-window-option -g window-status-fg $tm_color_inactive
set-window-option -g window-status-bg default
set -g window-status-format "#I #W"

# active window title colors
set-window-option -g window-status-current-fg $tm_color_active
set-window-option -g window-status-current-bg default
set-window-option -g  window-status-current-format "#[bold]#I #W"

# pane border
set-option -g pane-border-fg $tm_color_inactive
set-option -g pane-active-border-fg $tm_active_border_color

# message text
set-option -g message-bg default
set-option -g message-fg $tm_color_active

# pane number display
set-option -g display-panes-active-colour $tm_color_active
set-option -g display-panes-colour $tm_color_inactive

# clock
set-window-option -g clock-mode-colour $tm_clock_color

tm_tunes="#[fg=$tm_color_music,bold]#(osascript ~/.dotfiles/applescripts/tunes.scpt)"
tm_battery="#[fg=$dark_purple]#[bg=default] Batt: #{battery_percentage} #{battery_remain}"
tm_date="#[fg=$tm_clock_color] %a %h-%d %H:%M "
tm_host="#[fg=$tm_color_music]#[bg=$default]#h"
tm_session_name="#[fg=$tm_color_feature,bold]#S"
tm_cpu="#[fg=$tm_color_cpu,bold]#[bg=$default] CPU: #{cpu_icon} #{cpu_percentage}"

set -g status-left $tm_session_name' '$tm_icon' '
set -g status-right $tm_tunes' '$tm_icon' '$tm_date' '$tm_icon' '$tm_host'  '$tm_cpu' '$tm_icon' '$tm_battery
