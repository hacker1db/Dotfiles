#!/usr/bin/env bash
 
DOTFILES=$HOME/.dotfiles

# Ensure clitools repo is present before linking
CLITOOLS_DIR="$HOME/Developer/clitools"
if [ -z "${CLITOOLS_REPO_URL:-}" ]; then
    GH_USER=$(gh api user --jq '.login' 2>/dev/null || true)
    if [ -n "$GH_USER" ]; then
        CLITOOLS_REPO_URL="git@github.com:${GH_USER}/clitools.git"
    else
        echo "Warning: gh CLI not authenticated; skipping clitools clone"
        CLITOOLS_REPO_URL=""
    fi
fi
if [ -n "$CLITOOLS_REPO_URL" ] && [ ! -d "$CLITOOLS_DIR" ]; then
    echo "Cloning clitools repo to $CLITOOLS_DIR"
    mkdir -p "$(dirname "$CLITOOLS_DIR")"
    git clone "$CLITOOLS_REPO_URL" "$CLITOOLS_DIR" || echo "Failed to clone clitools; continuing without it"
elif [ -d "$CLITOOLS_DIR/.git" ]; then
    git -C "$CLITOOLS_DIR" fetch --quiet && git -C "$CLITOOLS_DIR" pull --ff-only --quiet || echo "Could not update clitools; using existing copy"
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

echo -e "\n\nInstalling Claude Code settings"
echo "=============================="
for CLAUDE_FILE in settings.json statusline-command.sh; do
  CLAUDE_SRC="$DOTFILES/claude/$CLAUDE_FILE"
  CLAUDE_DEST="$HOME/.claude/$CLAUDE_FILE"
  mkdir -p "$HOME/.claude"
  if [ -e "$CLAUDE_SRC" ]; then
    if [ -L "$CLAUDE_DEST" ]; then
      CURRENT=$(readlink "$CLAUDE_DEST")
      if [ "$CURRENT" != "$CLAUDE_SRC" ]; then
        rm "$CLAUDE_DEST"
        ln -s "$CLAUDE_SRC" "$CLAUDE_DEST"
        echo "Updated symlink $CLAUDE_DEST -> $CLAUDE_SRC"
      else
        echo "~/.claude/$CLAUDE_FILE already symlinked correctly."
      fi
    elif [ ! -e "$CLAUDE_DEST" ]; then
      ln -s "$CLAUDE_SRC" "$CLAUDE_DEST"
      echo "Created symlink $CLAUDE_DEST -> $CLAUDE_SRC"
    else
      echo "~/.claude/$CLAUDE_FILE exists but is not a symlink; skipping."
    fi
  fi
done

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

echo -e "\n\nAdopting any unmanaged Claude skills into dotfiles"
echo "=============================="
if [ -d "$HOME/.claude/skills" ]; then
  for skill_dir in "$HOME/.claude/skills"/*/; do
    skill_name="$(basename "$skill_dir")"
    [ -L "${skill_dir%/}" ] && continue
    [ ! -f "$skill_dir/SKILL.md" ] && continue
    dotfiles_dest="$DOTFILES/claude/skills/$skill_name"
    [ -e "$dotfiles_dest" ] && continue
    echo "Adopting $skill_name into dotfiles..."
    mv "$skill_dir" "$dotfiles_dest"
    ln -s "$dotfiles_dest" "${skill_dir%/}"
  done
fi

echo -e "\n\nInstalling Claude Code skills"
echo "=============================="
link_skill_dir() {
  local dest_dir="$1"
  local display_dir="$2"
  if ! mkdir -p "$dest_dir"; then
    echo "Could not create $display_dir; skipping."
    return
  fi
  for SKILL_SRC in "$DOTFILES/claude/skills"/*/; do
    if [ -f "$SKILL_SRC/SKILL.md" ]; then
      SKILL_NAME=$(basename "$SKILL_SRC")
      SKILL_DEST="$dest_dir/$SKILL_NAME"
      if [ -L "$SKILL_DEST" ]; then
        CURRENT=$(readlink "$SKILL_DEST")
        if [ "$CURRENT" != "${SKILL_SRC%/}" ]; then
          rm "$SKILL_DEST"
          ln -s "${SKILL_SRC%/}" "$SKILL_DEST"
          echo "Updated symlink $SKILL_DEST -> ${SKILL_SRC%/}"
        else
          echo "$display_dir/$SKILL_NAME already symlinked correctly."
        fi
      elif [ ! -e "$SKILL_DEST" ]; then
        if ln -s "${SKILL_SRC%/}" "$SKILL_DEST"; then
          echo "Created symlink $SKILL_DEST -> ${SKILL_SRC%/}"
        else
          echo "Could not create symlink $SKILL_DEST -> ${SKILL_SRC%/}"
        fi
      else
        echo "$display_dir/$SKILL_NAME exists but is not a symlink; skipping."
      fi
    fi
  done
}

link_skill_dir "$HOME/.claude/skills" "~/.claude/skills"

echo -e "\n\nInstalling Copilot CLI skills"
echo "=============================="
link_skill_dir "$HOME/.agents/skills" "~/.agents/skills"

echo -e "\n\nInstalling Codex CLI skills"
echo "=============================="
link_skill_dir "$HOME/.codex/skills" "~/.codex/skills"

echo -e "\n\nInstalling OpenCode skills"
echo "=============================="
link_skill_dir "$HOME/.opencode/skills" "~/.opencode/skills"

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
