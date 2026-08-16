####################
# functions
####################

function daily() {
    local date="${1:-$(date +%Y-%m-%d)}"
    local note="$HOME/notes/SecondBrain/0.Quick Notes 📨/Daily Stuff/${date}.md"
    tmux new-window -n "${date}" "nvim '${note}'" 2>/dev/null || nvim "$note"
}

# print available colors and their numbers
function colours() {
    for i in {0..255}; do
        printf "\x1b[38;5;${i}m colour${i}"
        if (( $i % 5 == 0 )); then
            printf "\n"
        else
            printf "\t"
        fi
    done
}

function ghmerge(){
gh pr view "$1" --json state -q '.state' -q '.state' | grep -q "OPEN" && gh pr diff "$1" && printf "Approve and merge PR #$1? [y/N] " && read ans && { [[ $ans =~ ^[Yy]$ ]] && gh pr review "$1" --approve && gh pr merge "$1" --rebase || echo "Canceled."; }
}

function gitsign(){
    if [[ ! -z "$SIGNING_KEY_PUBLIC" ]]; then
        export SIGNING_KEY_PUBLIC=$(op item get "Github Work" --format json | jq -r '.fields[] | select(.id=="public_key") | .value' )
    fi
    if [[ ! -f ~/.ssh/allowed_signers ]]; then
        echo "$(git config user.email) $SIGNING_KEY_PUBLIC" >> ~/.ssh/allowed_signers
    fi
}
function ts(){
  sesh connect "$(sesh list -i | gum filter --limit 1 --placeholder 'Pick a sesh' --prompt='⚡')"
}

function sesh-sessions() {
  {
    exec </dev/tty
    exec <&1
    local session
    session=$(sesh list -t -c | fzf --height 40% --reverse --border-label ' sesh ' --border --prompt '⚡  ')
    zle reset-prompt > /dev/null 2>&1 || true
    [[ -z "$session" ]] && return
    sesh connect $session
  }
}

zle     -N             sesh-sessions
bindkey -M emacs '\es' sesh-sessions
bindkey -M vicmd '\es' sesh-sessions
bindkey -M viins '\es' sesh-sessions

function cx() { cd "$@" && l; }
# Create a new directory and enter it
function md() {
    mkdir -p "$@" && cd "$@"
}

function db() {
    DOCKERFILE="${1:-.}"
    IMAGENAME="${2:-tempname}"
    PATTOKEN="${3:-$PAT}"

    echo "Building $DOCKERFILE with $IMAGENAME"

    docker build -f "$DOCKERFILE" -t $IMAGENAME:tempbuild$RANDOM --build-arg PAT=$PATTOKEN .
}

function clitools(){
if [[ -d $CODE_DIR/clitools ]]; then
     cd $CODE_DIR/clitools
else
gh repo clone hacker1db/clitools $CODE_DIR/clitools
fi

}

# Create a new secure code review worktree
# Usage: newreview <name> [-i <issue-number>] [-p]
function newreview(){
  if [[ ! -d $CODE_DIR/clitools ]]; then
    echo "clitools not found. Cloning..."
    gh repo clone hacker1db/clitools $CODE_DIR/clitools
  fi
  $CODE_DIR/clitools/new-secure-review.sh "$@"
}

alias bathelp='bat --plain --language=help'
help() {
    "$@" --help 2>&1 | bathelp
}

function bd() {
    git diff --name-only --relative --diff-filter=d | xargs bat --diff
}


function hist() {
    history | awk '{a[$2]++}END{for(i in a){print a[i] " " i}}' | sort -rn | head
}

# find shorthand
function f() {
    find . -name "$1"
}


# Start an HTTP server from a directory, optionally specifying the port
function server() {
    # local port="${1:-8000}"
    # open "http://localhost:${port}/"
    # Set the default Content-Type to `text/plain` instead of `application/octet-stream`
    # And serve everything as UTF-8 (although not technically correct, this doesn’t break anything for binary files)
    # python3 -c $'import SimpleHTTPServer;\nmap = SimpleHTTPServer.SimpleHTTPRequestHandler.extensions_map;\nmap[""] = "text/plain";\nfor key, value in map.items():\n\tmap[key] = value + ";charset=UTF-8";\nSimpleHTTPServer.test();' "$port"
    python3 -m http.server
}


# take this repo and copy it to somewhere else minus the .git stuff.
function gitexport(){
    mkdir -p "$1"
    git archive master | tar -x -C "$1"
}

# get gzipped size
function gz() {
    echo "orig size    (bytes): "
    cat "$1" | wc -c
    echo "gzipped size (bytes): "
    gzip -c "$1" | wc -c
}

# All the dig info
function digga() {
    dig +nocmd "$1" any +multiline +noall +answer
}

# Escape UTF-8 characters into their 3-byte format
function escape() {
    printf "\\\x%s" $(printf "$@" | xxd -p -c1 -u)
    echo # newline
}

# Decode \x{ABCD}-style Unicode escape sequences
function unidecode() {
    perl -e "binmode(STDOUT, ':utf8'); print \"$@\""
    echo # newline
}

# Extract archives - use: extract <file>
# Credits to http://dotfiles.org/~pseup/.bashrc
function extract() {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2) tar xjf $1 ;;
            *.tar.gz) tar xzf $1 ;;
            *.bz2) bunzip2 $1 ;;
            *.rar) rar x $1 ;;
            *.gz) gunzip $1 ;;
            *.tar) tar xf $1 ;;
            *.tbz2) tar xjf $1 ;;
            *.tgz) tar xzf $1 ;;
            *.zip) unzip $1 ;;
            *.Z) uncompress $1 ;;
            *.7z) 7z x $1 ;;
            *) echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# syntax highlight the contents of a file or the clipboard and place the result on the clipboard
function hl() {
    if [ -z "$3" ]; then
        src=$( pbpaste )
    else
        src=$( cat $3 )
    fi

    if [ -z "$2" ]; then
        style="moria"
    else
        style="$2"
    fi

    echo $src | highlight -O rtf --syntax $1 --font Inconsoloata --style $style --line-number --font-size 24 | pbcopy
}


function set-ns() {
kubectl config set-context --current --namespace="$@"
}

function mds(){
    glow -p "$@" -s dark | less -r
}

function cytj(){
    yq -Poy "$@"
}

function azdlogin(){
        if [ -z "$1" ]; then
            echo "Usage: dlogin <registry>"
            return 1
       fi
    az acr login -n "$@" --expose-token --query 'accessToken' -o tsv | podman login -u 00000000-0000-0000-0000-000000000000 --password-stdin "$@.azurecr.io"
}
function gha(){
       gh project item-add 16 --owner Alaska-ITS --url "$@"
}
function brew-cleanup(){
    local brewfile="${DOTFILES:-$HOME/.dotfiles}/install/brewfile"
    local snapshot
    local formula
    local -a missing_formulae

    if [[ ! -f "$brewfile" ]]; then
        echo "Brewfile not found: $brewfile"
        return 1
    fi

    snapshot="$(mktemp "${TMPDIR:-/tmp}/brewfile.XXXXXX")" || return 1
    command brew bundle dump --mas --tap --cask --brews --file="$snapshot" --force || {
        rm -f "$snapshot"
        return 1
    }

    for formula in ${(f)"$(command brew leaves)"}; do
        if ! awk -v target="$formula" '
            /^brew "/ {
                name = $0
                sub(/^brew "/, "", name)
                sub(/".*/, "", name)
                count = split(name, parts, "/")
                if (parts[count] == target) found = 1
            }
            END { exit(found ? 0 : 1) }
        ' "$snapshot"; then
            missing_formulae+=("$formula")
        fi
    done

    if (( ${#missing_formulae[@]} )); then
        echo "Brewfile was not updated; the dump omitted installed formulae: ${missing_formulae[*]}"
        rm -f "$snapshot"
        return 1
    fi

    mv "$snapshot" "$brewfile"
    command brew cleanup || return 1
    command brew doctor
}

function update-node-tools(){
if ! command -v pnpm >/dev/null 2>&1; then
  echo "pnpm not found."
  return 1
fi

export PNPM_HOME="${PNPM_HOME:-$HOME/Library/pnpm}"
mkdir -p "$PNPM_HOME"
export PATH="$PNPM_HOME/bin:$PNPM_HOME:$PATH"

if ! pnpm list --global --depth -1 2>/dev/null | grep -Eq '^[├└]── '; then
  echo "No global pnpm packages found."
  if command -v npm >/dev/null 2>&1; then
    local npm_global_count
    npm_global_count="$(npm list -g --depth=0 2>/dev/null | grep -Ec '^[├└]── ' || true)"
    if [[ "${npm_global_count:-0}" -gt 0 ]]; then
      echo "Found ${npm_global_count} npm global package(s). Run: npm update -g"
    fi
  fi
  return 0
fi

echo "Updating global pnpm packages..."
pnpm update --global --latest
echo "All global pnpm packages updated!"
}

function get-azsubcount(){

    count=$(az account list --all | jq '.[].name' | wc | awk '{print $1}')
    echo "You have $count Azure subscriptions"
}
## Set DOCKER_HOST to point to Podman socket
function docker_set_host_to_podman_socket()
{
    local socket_path="$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}')"
    local unix_domain_socket="unix://$socket_path"
    echo "Setting DOCKER_HOST=$unix_domain_socket"
    export DOCKER_HOST="$unix_domain_socket"
}

function drawio-open() {
    local root="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
    local -a files
    files=("${(@f)$(find "$root" \( -name "*.drawio.png" -o -name "*.drawio" \) 2>/dev/null)}")
    (( ${#files} )) || { echo "No draw.io diagrams found in $root"; return 1; }
    open -a draw.io "${files[@]}"
}

# Scaffold BMAD-METHOD into the current project (Claude Code + Codex).
# Extra args pass through, e.g. `bmad-init --directory .`.
# Set GITHUB_TOKEN first to avoid the 60/hr anonymous GitHub API rate limit
# when the external modules (bmb, cis) resolve their release tags.
function bmad-init() {
  bmad-method install --yes \
    --modules bmm,bmb,cis \
    --tools claude-code,codex "$@"
}
