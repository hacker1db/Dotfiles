# reload zsh config
alias reload!='source ~/.zshrc'
alias r!='reload!'
alias e!="nvim ~/.dotfiles/config/nvim/init.vim"
# Detect which `ls` flavor is in use
if ls --color > /dev/null 2>&1; then # GNU `ls`
    colorflag="--color"
else # OS X `ls`
    colorflag="-G"
fi

alias vim="nvim"
alias vi="nvim"
alias f="flutter"
alias gitpulla='find . -mindepth 1 -maxdepth 1 -type d -print -exec git -C {} pull \;'
# Filesystem aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias cat='bat'
alias tf="terraform"
alias l="ls -lah ${colorflag}"
alias la="ls -AF ${colorflag}"
if [[ -x "$(command -v exa)" ]]; then
  alias ll="exa --icons --git --long -a"
  alias l="exa --icons --git --all --long"
fi
alias lld="ls -l | grep ^d"
alias rmf="rm -rf"
alias tree='exa -l --icons --tree -a -g'
alias wv='gh repo view --web'
# moving dir 
alias sites='cd $CODE_DIR/Sites/'
alias notes='cd ~/notes/Second\ Brain'

# Helpers
alias grep='grep --color=auto'
alias df='df -h' # disk free, in Gigabytes, not bytes
alias du='du -h -c' # calculate disk usage for a folder
alias dotfiles="cd ~/.dotfiles"

# Applications
alias ios='open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app'
alias pnp='pnpm'
alias jwtp='jwt $(pbpaste)' 
alias docker='nerdctl.lima'





# IP addresses
alias publicip="pwsh -c '(Invoke-WebRequest ifconfig.me/ip).Content.Trim()'"
alias localip="ipconfig getifaddr en1"
alias ips="ifconfig -a | perl -nle'/(\d+\.\d+\.\d+\.\d+)/ && print $1'"
alias k="kubectl"
# Flush Directory Service cache
alias flush="dscacheutil -flushcache"

# View HTTP traffic
alias sniff="sudo ngrep -d 'en1' -t '^(GET|POST) ' 'tcp and port 80'"
alias httpdump="sudo tcpdump -i en1 -n -s 0 -w - | grep -a -o -E \"Host\: .*|GET \/.*\""

# Trim new lines and copy to clipboard
alias trimcopy="tr -d '\n' | pbcopy"

# Recursively delete `.DS_Store` files
alias cleanup="find . -name '*.DS_Store' -type f -ls -delete"

# File size
alias fs="stat -f \"%z bytes\""

# ROT13-encode text. Works for decoding, too! ;)
alias rot13='tr a-zA-Z n-za-mN-ZA-M'

# Empty the Trash on all mounted volumes and the main HDD
alias emptytrash="sudo rm -rfv /Volumes/*/.Trashes; rm -rfv ~/.Trash"

# Hide/show all desktop icons (useful when presenting)
alias hidedesktop="defaults write com.apple.finder CreateDesktop -bool false && killall Finder"
alias showdesktop="defaults write com.apple.finder CreateDesktop -bool true && killall Finder"

# One of @janmoesen’s ProTip™s
for method in GET HEAD POST PUT DELETE TRACE OPTIONS; do
    alias "$method"="lwp-request -m '$method'"
done

# Stuff I never really use but cannot delete either because of http://xkcd.com/530/
alias stfu="osascript -e 'set volume output muted true'"
alias pumpitup="osascript -e 'set volume 10'"

# Kill all the tabs in Chrome to free up memory
# [C] explained: http://www.commandlinefu.com/commands/view/402/exclude-grep-from-your-grepped-output-of-ps-alias-included-in-description
alias chromekill="ps ux | grep '[C]hrome Helper --type=renderer' | grep -v extension-process | tr -s ' ' | cut -d ' ' -f2 | xargs kill"

alias chrome="/Applications/Google\\ \\Chrome.app/Contents/MacOS/Google\\ \\Chrome"
alias canary="/Applications/Google\\ Chrome\\ Canary.app/Contents/MacOS/Google\\ Chrome\\ Canary"
alias rundj="python manage.py runserver 7000"
alias httpgui="open\ /Applications/HTTPie.app"

# Azure CLI aliases
alias azlocations='az account list-locations -o table'
alias azlogin='az login'
alias azlogout='az logout'
