#!/usr/bin/env bash
 
DOTFILES=$HOME/.dotfiles

# Ensure clitools repo is present before linking
CLITOOLS_DIR="$HOME/Developer/clitools"
CLITOOLS_REPO_URL=${CLITOOLS_REPO_URL:-git@github.com:CyberDSO/clitools.git}
if [ ! -d "$CLITOOLS_DIR" ]; then
    echo "Cloning clitools repo to $CLITOOLS_DIR"
    mkdir -p "$(dirname "$CLITOOLS_DIR")"
    git clone "$CLITOOLS_REPO_URL" "$CLITOOLS_DIR" || echo "Failed to clone clitools; continuing without it"
else
    if [ -d "$CLITOOLS_DIR/.git" ]; then
        git -C "$CLITOOLS_DIR" fetch --quiet && git -C "$CLITOOLS_DIR" pull --ff-only --quiet || echo "Could not update clitools; using existing copy"
    fi
fi


echo -e "\nCreating symlinks"
echo "=============================="
linkables=$(find -H "$DOTFILES" -maxdepth 3 -name '*.symlink')
for file in $linkables; do
    target="$HOME/.$(basename $file '.symlink')"
    if [ -e "$target" ]; then
        echo "~${target#$HOME} already exists... Skipping."
    else
        echo "Creating symlink for $file"
        ln -s "$file" "$target"
    fi
done

echo -e "\n\ninstalling to ~/.config"
echo "=============================="
if [ ! -d "$HOME/.config" ]; then
    echo "Creating ~/.config"
    mkdir -p "$HOME/.config"
fi

for config in $DOTFILES/config/*; do
    target="$HOME/.config/$(basename "$config")"
    if [ -e "$target" ]; then
        echo "~${target#$HOME} already exists... Skipping."
    else
        echo "Creating symlink for $config"
        ln -s "$config" "$target"
    fi
done

OPENCODE_SRC="$DOTFILES/config/opencode"
OPENCODE_DEST="$HOME/.config/opencode"
if [ -e "$OPENCODE_SRC" ]; then
  if [ -L "$OPENCODE_DEST" ]; then
    CURRENT=$(readlink "$OPENCODE_DEST")
    if [ "$CURRENT" != "$OPENCODE_SRC" ]; then
      rm "$OPENCODE_DEST"
      ln -s "$OPENCODE_SRC" "$OPENCODE_DEST"
    fi
  else
    rm -rf "$OPENCODE_DEST"
    ln -s "$OPENCODE_SRC" "$OPENCODE_DEST"
  fi
fi

echo -e "\n\nInstalling Claude Code agents and commands"
echo "=============================="
for CLAUDE_SRC in "$DOTFILES/claude/agents" "$DOTFILES/claude/commands"; do
  DIR_NAME=$(basename "$CLAUDE_SRC")
  CLAUDE_DEST="$HOME/.claude/$DIR_NAME"
  mkdir -p "$HOME/.claude"
  if [ -e "$CLAUDE_SRC" ]; then
    if [ -L "$CLAUDE_DEST" ]; then
      CURRENT=$(readlink "$CLAUDE_DEST")
      if [ "$CURRENT" != "$CLAUDE_SRC" ]; then
        rm "$CLAUDE_DEST"
        ln -s "$CLAUDE_SRC" "$CLAUDE_DEST"
        echo "Updated symlink $CLAUDE_DEST -> $CLAUDE_SRC"
      else
        echo "~/.claude/$DIR_NAME already symlinked correctly."
      fi
    elif [ ! -e "$CLAUDE_DEST" ]; then
      ln -s "$CLAUDE_SRC" "$CLAUDE_DEST"
      echo "Created symlink $CLAUDE_DEST -> $CLAUDE_SRC"
    else
      echo "~/.claude/$DIR_NAME exists but is not a symlink; skipping."
    fi
  fi
done

echo -e "\n\nInstalling Claude Code MCP servers"
echo "=============================="
MCP_SRC="$DOTFILES/claude/mcp.json"
MCP_DEST="$HOME/.mcp.json"
if [ -e "$MCP_SRC" ]; then
  if [ -L "$MCP_DEST" ]; then
    CURRENT=$(readlink "$MCP_DEST")
    if [ "$CURRENT" != "$MCP_SRC" ]; then
      rm "$MCP_DEST"
      ln -s "$MCP_SRC" "$MCP_DEST"
      echo "Updated symlink $MCP_DEST -> $MCP_SRC"
    else
      echo "~/.mcp.json already symlinked correctly."
    fi
  elif [ ! -e "$MCP_DEST" ]; then
    ln -s "$MCP_SRC" "$MCP_DEST"
    echo "Created symlink $MCP_DEST -> $MCP_SRC"
  else
    echo "~/.mcp.json exists but is not a symlink; skipping."
  fi
fi

echo -e "\n\nCreating vim symlinks"
echo "=============================="
VIMFILES=("$HOME/.vim:$DOTFILES/vim/.vim" "$HOME/.vimrc:$DOTFILES/vim/.vimrc")
for file in "${VIMFILES[@]}"; do
    KEY=${file%%:*}
    VALUE=${file#*:}
    if [ -e "$KEY" ]; then
        echo "${KEY} already exists... skipping."
    else
        echo "Creating symlink for $KEY"
        ln -s "$VALUE" "$KEY"
    fi
done

echo -e "\n\nCreating zshrc symlinks"
echo "=============================="
ZSHRC=("$HOME/.zshrc:$DOTFILES/zsh/zshrc.symlink")
for file in "${ZSHRC[@]}"; do
    KEY=${file%%:*}
    VALUE=${file#*:}
    if [ -e "$KEY" ]; then
        echo "${KEY} already exists... skipping."
    else
        echo "Creating symlink for $KEY"
        ln -s "$VALUE" "$KEY"
    fi
done

echo -e "\n\nEnsuring ~/.gitconfig-local link"
echo "=============================="
LOCAL_FILE="$HOME/.gitconfig-local"
CLITOOLS_DIR_DEFAULT="$HOME/Developer/clitools"
SOURCE_CANDIDATE=""
if [ -d "$CLITOOLS_DIR_DEFAULT" ]; then
  for f in gitconfig-local .gitconfig-local gitconfig.local; do
    if [ -f "$CLITOOLS_DIR_DEFAULT/$f" ]; then
      SOURCE_CANDIDATE="$CLITOOLS_DIR_DEFAULT/$f"
      break
    fi
  done
fi
if [ -n "$SOURCE_CANDIDATE" ]; then
  if [ -L "$LOCAL_FILE" ]; then
    CURRENT_TARGET=$(readlink "$LOCAL_FILE")
    if [ "$CURRENT_TARGET" != "$SOURCE_CANDIDATE" ]; then
      rm "$LOCAL_FILE"
      ln -s "$SOURCE_CANDIDATE" "$LOCAL_FILE"
      echo "Updated symlink $LOCAL_FILE -> $SOURCE_CANDIDATE"
    else
      echo "Symlink $LOCAL_FILE already points to candidate."
    fi
  else
    if [ -e "$LOCAL_FILE" ]; then
      rm -rf "$LOCAL_FILE"
    fi
    ln -s "$SOURCE_CANDIDATE" "$LOCAL_FILE"
    echo "Linked $LOCAL_FILE -> $SOURCE_CANDIDATE"
  fi
else
  if [ ! -e "$LOCAL_FILE" ]; then
    touch "$LOCAL_FILE"
    echo "Created empty $LOCAL_FILE (no clitools source found)"
  else
    echo "$LOCAL_FILE exists (no clitools source found); leaving as-is."
  fi
fi
