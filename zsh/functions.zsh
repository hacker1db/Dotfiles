####################
# functions
####################

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
 brew bundle dump --mas --tap --cask --brews --describe -v  --file="$HOME/.dotfiles/install/brewfile" -f  && brew cleanup && brew doctor
}

function update-bun-tools(){
echo "🔍 Getting list of globally installed bun packages..."
packages=$(bun pm ls -g 2>/dev/null | awk 'NR>1 {print $2}' | sed 's/@[^@]*$//')

if [ -z "$packages" ]; then
  echo "No global packages found."
  return 0
fi

echo "📦 Updating the following packages:"
echo "$packages"

echo "$packages" | while IFS= read -r pkg; do
  if [ -n "$pkg" ]; then
    if [ "$pkg" = "@github/copilot" ]; then
      echo "⬆️ 🤖 updating copilot separately $pkg..."
      bun add -g "$pkg@latest"
      continue
    fi
    echo "⬆️  updating $pkg..."
    bun add -g "$pkg@latest"
  fi
done

echo "✅ All global bun packages updated!"
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
