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
function gitsign(){
    if [[ ! -z "$SIGNING_KEY_PUBLIC" ]]; then
        export SIGNING_KEY_PUBLIC=$(op item get "Github Work" --format json | jq -r '.fields[] | select(.id=="public_key") | .value' )
    fi
    export SIGNING_KEY_PUBLIC=$(op item get "Github Work" --format json | jq -r '.fields[] | select(.id=="public_key") | .value' )
    if [[ ! -f ~/.ssh/allowed_signers ]]; then
        echo "$(git config user.email) $SIGNING_KEY" >> ~/.ssh/allowed_signers
    fi
}


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

function docker-init(){
    limactl start template://docker
    export DOCKER_HOST=$(limactl list docker --format 'unix://{{.Dir}}/sock/docker.sock')
}
function cytj(){
    yq -Poy "$@"
}

function azdlogin(){
        if [ -z "$1" ]; then
            echo "Usage: dlogin <registry>"
            return 1
       fi
    az acr login -n "$@" --expose-token --query 'accessToken' -o tsv | lima nerdctl login -u 00000000-0000-0000-0000-000000000000 --password-stdin "$@.azurecr.io"
}
function gha(){
       gh project item-add 16 --owner Alaska-ITS --url "$@"
}
