# git aliases
alias ga='git add'
alias gb='git branch'
alias gl='git pull'
alias gp='git push'
alias gd='git diff --name-only --relative --diff-filter=d | xargs bat --diff'
alias gdc='git diff --cached --name-only --relative --diff-filter=d | xargs bat --diff'
alias gs='git s'
alias gss='git stash save'
alias gsp='git stash pop'
alias gmv='git mv'
alias grm='git rm'
alias grn='git-rename'
alias glog="git l"
alias gcm="git commit -am"
alias gcs="git commit -S -am"
alias gds="git diff --name-only --relative --diff-filter=d --staged | xargs bat --diff"

# alias git-amend='git commit --amend -C HEAD'
alias git-undo='git reset --soft HEAD~1'
alias git-count='git shortlog -sn'
alias git-undopush="git push -f origin HEAD^:master"
alias cpbr="git rev-parse --abbrev-ref HEAD | pbcopy"
# git root
alias gr='[ ! -z `git rev-parse --show-cdup` ] && cd `git rev-parse --show-cdup || pwd`'

alias sub-pull='git submodule foreach git pull origin master'

function give-credit() {
    git commit --amend --author $1 <$2> -C HEAD
}

# a simple git rename file function
# git does not track case-sensitive changes to a filename.
function git-rename() {
    git mv $1 "${2}-"
    git mv "${2}-" $2
}

function g() {
    if [[ $# > 0 ]]; then
        # if there are arguments, send them to git
        git $@
    else
        # otherwise, run git status
        git s
    fi
}

function ghi(){
 if [[ $# > 0 ]]; then
    number="#"
    gh issue view "${number}$@"
    else
        gh issue list 
    fi
}




# TODO: FIX the follow GitHub issue script
# function fzf_git_issue(){
#   set -l query (commandline --current-buffer)
#   if test -n $query then
#     set fzf_query --query "$query"
#   fi
#
#   set -l base_command gh issue list --limit 100
#   set -l bind_commands "ctrl-a:reload($base_command --state all)"
#   set bind_commands $bind_commands "ctrl-o:reload($base_command --state open)"
#   set bind_commands $bind_commands "ctrl-c:reload($base_command --state closed)"
#   set -l bind_str (string join ',' $bind_commands)
#
#   set -l out ( \
#     command $base_command | \
#     fzf $fzf_query \
#         --prompt='Open issue list >' \
#         --preview "gh issue view {1}" \
#         --bind $bind_str \
#         --header='C-a: all, C-o: open, C-c: closed' \
#   )
#   if test -z $out then
#     return
#   fi
#   set -l issue_id (echo $out | awk '{ print $1 }')
#   commandline "gh issue view -w $issue_id"
#   commandline -f execute
#
# }
