#!/usr/bin/env bash
 
DOTFILES=$HOME/.dotfiles
source "$DOTFILES/install/lib/log.sh"
source "$DOTFILES/install/lib/env.sh"

github_ssh_preflight >&2 || true

# Ensure clitools repo is present before linking
CLITOOLS_DIR="$HOME/Developer/clitools/main"
if [ -z "${CLITOOLS_REPO_URL:-}" ]; then
    GH_USER=$(github_owner || true)
    if [ -n "$GH_USER" ]; then
        CLITOOLS_REPO_URL="$(github_repo_url "${GH_USER}/clitools")"
    else
        echo "Warning: GitHub owner could not be determined (set DOTFILES_GITHUB_OWNER); skipping clitools clone"
        CLITOOLS_REPO_URL=""
    fi
fi
if [ -n "$CLITOOLS_REPO_URL" ] && [ ! -d "$CLITOOLS_DIR" ]; then
    echo "Cloning clitools repo to $CLITOOLS_DIR"
    mkdir -p "$(dirname "$CLITOOLS_DIR")"
    github_clone "$CLITOOLS_REPO_URL" "$CLITOOLS_DIR" || echo "Failed to clone clitools; continuing without it"
elif [ -e "$CLITOOLS_DIR/.git" ]; then
    github_git -C "$CLITOOLS_DIR" fetch --quiet && github_git -C "$CLITOOLS_DIR" pull --ff-only --quiet || echo "Could not update clitools; using existing copy"
fi

PLAN_MANAGER_READY=0
PLAN_MANAGER_FAILURE=0
if [ -r "$DOTFILES/install/plan-manager-bootstrap.sh" ]; then
  source "$DOTFILES/install/plan-manager-bootstrap.sh"
  if bootstrap_plan_repo && install_plan_cli; then
    PLAN_MANAGER_READY=1
  else
    PLAN_MANAGER_FAILURE=1
    warning "Plan-manager bootstrap did not complete; continuing other dotfiles links."
  fi
else
  PLAN_MANAGER_FAILURE=1
  echo "Warning: plan-manager bootstrap helper is missing."
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
if [[ -d "$OPENCODE_SRC" && ! "$OPENCODE_SRC" -ef "$OPENCODE_DEST" ]]; then
    if [[ -d "$OPENCODE_DEST" && ! -L "$OPENCODE_DEST" ]]; then
        echo "$OPENCODE_DEST is an unmanaged directory; preserving it and linking only managed files."
    else
        if [[ -e "$OPENCODE_DEST" || -L "$OPENCODE_DEST" ]]; then
            OPENCODE_BACKUP_BASE="$OPENCODE_DEST.backup.$(date +%Y%m%d%H%M%S)"
            OPENCODE_BACKUP=$OPENCODE_BACKUP_BASE
            OPENCODE_BACKUP_SUFFIX=0
            while [[ -e "$OPENCODE_BACKUP" || -L "$OPENCODE_BACKUP" ]]; do
                OPENCODE_BACKUP_SUFFIX=$((OPENCODE_BACKUP_SUFFIX + 1))
                OPENCODE_BACKUP="$OPENCODE_BACKUP_BASE.$OPENCODE_BACKUP_SUFFIX"
            done
            mv "$OPENCODE_DEST" "$OPENCODE_BACKUP" || exit 1
            echo "Preserved existing OpenCode config: $OPENCODE_BACKUP"
        fi
        ln -s "$OPENCODE_SRC" "$OPENCODE_DEST" || exit 1
    fi
fi

bash "$DOTFILES/install/agent-instructions.sh" || exit 1

echo -e "\n\nInstalling Claude Code settings"
echo "=============================="
for CLAUDE_FILE in statusline-command.sh; do
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

if [ -x "$DOTFILES/install/claude-backend.sh" ]; then
  "$DOTFILES/install/claude-backend.sh" || echo "Warning: Claude Code settings backend link failed; continuing."
else
  echo "Warning: $DOTFILES/install/claude-backend.sh is not executable; skipping Claude Code settings backend link."
fi

python3 "$DOTFILES/install/claude-profiles.py" || echo "Warning: Claude profile setup incomplete; see the reported local prerequisites."

echo -e "\n\nInstalling Claude Code agents and commands"
echo "=============================="
for CLAUDE_SRC in "$DOTFILES/claude/agents" "$DOTFILES/claude/commands" "$DOTFILES/claude/output-styles"; do
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

echo -e "\n\nInstalling SSH config"
echo "=============================="
SSH_SRC="$DOTFILES/ssh/config"
SSH_DEST="$HOME/.ssh/config"
if [ -e "$SSH_SRC" ]; then
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  chmod 600 "$SSH_SRC"
  if [ -L "$SSH_DEST" ]; then
    CURRENT=$(readlink "$SSH_DEST")
    if [ "$CURRENT" != "$SSH_SRC" ]; then
      rm "$SSH_DEST"
      ln -s "$SSH_SRC" "$SSH_DEST"
      echo "Updated symlink $SSH_DEST -> $SSH_SRC"
    else
      echo "~/.ssh/config already symlinked correctly."
    fi
  elif [ ! -e "$SSH_DEST" ]; then
    ln -s "$SSH_SRC" "$SSH_DEST"
    echo "Created symlink $SSH_DEST -> $SSH_SRC"
  else
    echo "~/.ssh/config exists but is not a symlink; skipping."
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
CLITOOLS_DIR_DEFAULT="$HOME/Developer/clitools/main"
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
      LOCAL_BACKUP_BASE="$LOCAL_FILE.backup.$(date +%Y%m%d%H%M%S)"
      LOCAL_BACKUP=$LOCAL_BACKUP_BASE
      LOCAL_BACKUP_SUFFIX=0
      while [[ -e "$LOCAL_BACKUP" || -L "$LOCAL_BACKUP" ]]; do
        LOCAL_BACKUP_SUFFIX=$((LOCAL_BACKUP_SUFFIX + 1))
        LOCAL_BACKUP="$LOCAL_BACKUP_BASE.$LOCAL_BACKUP_SUFFIX"
      done
      mv "$LOCAL_FILE" "$LOCAL_BACKUP" || exit 1
      echo "Preserved existing $LOCAL_FILE: $LOCAL_BACKUP"
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

if [ "$PLAN_MANAGER_READY" -eq 1 ]; then
  if ! install_plan_instruction_links ||
     ! reconcile_codex_config ||
     ! initialize_plan_library ||
     ! install_plan_launch_agent ||
     ! check_plan_manager; then
    PLAN_MANAGER_FAILURE=1
  fi
fi

if [ "$PLAN_MANAGER_FAILURE" -ne 0 ]; then
  echo "Dotfiles installation needs attention; see the diagnostics above."
  exit 1
fi
