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

function cob() {
  wt switch --create "$@"
}

function cobc() {
    if [[ $# -lt 1 ]]; then
        print -u2 "usage: cobc <branch> [wt switch options]"
        return 2
    fi
    wt switch --create "$1" --base @ "${@:2}"
}

function git-clean-merged() {
  git fetch --prune
  git worktree prune
  git branch --merged | grep -vE '^\*|^\+|main|master|develop' | xargs -r git branch -d
  git branch -r --merged | grep -vE 'origin/main|origin/master|origin/develop|HEAD' \
    | sed 's/origin\///' | xargs -r git push origin --delete
}

function ghi(){
 if [[ $# > 0 ]]; then
    number="#"
    gh issue view "${number}$@"
    else
        gh issue list 
    fi
}
function gitinit(){
 pwsh -f "~/Developer/clitools/main/initializeGitRepo.ps1 -GithubOrg $1"
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
