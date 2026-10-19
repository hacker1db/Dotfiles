#!/usr/bin/env bash
 
DOTFILES=$HOME/.dotfiles/main
LINK_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"
source "$LINK_LIB/log.sh"
source "$LINK_LIB/env.sh"

LINK_PHASE="${DOTFILES_LINK_PHASE:-all}"
case "$LINK_PHASE" in
    files|integrations|all) ;;
    *) echo "Unknown DOTFILES_LINK_PHASE: $LINK_PHASE (expected files, integrations or all)" >&2; exit 1 ;;
esac

echo -e "\nCreating symlinks"
echo "=============================="
linkables=$(find -H "$DOTFILES" -maxdepth 3 -name '*.symlink')
for file in $linkables; do
    target="$HOME/.$(basename $file '.symlink')"
    if [[ "$(basename "$file")" == gitconfig.symlink ]]; then
        [[ "$LINK_PHASE" == files ]] && continue
    else
        [[ "$LINK_PHASE" == integrations ]] && continue
    fi
    [ -L "$target" ] && [ ! -e "$target" ] && rm "$target"
    if [ -e "$target" ]; then
        echo "~${target#$HOME} already exists... Skipping."
    else
        echo "Creating symlink for $file"
        ln -s "$file" "$target"
    fi
done

if [[ "$LINK_PHASE" != integrations ]]; then
    echo -e "\n\ninstalling to ~/.config"
    echo "=============================="
    if [ ! -d "$HOME/.config" ]; then
        echo "Creating ~/.config"
        mkdir -p "$HOME/.config"
    fi

    for config in $DOTFILES/config/*; do
        [ "$(basename "$config")" = opencode ] && continue  # opencode-config.sh links it per entry
        target="$HOME/.config/$(basename "$config")"
        [ -L "$target" ] && [ ! -e "$target" ] && rm "$target"
        if [ -e "$target" ]; then
            echo "~${target#$HOME} already exists... Skipping."
        else
            echo "Creating symlink for $config"
            ln -s "$config" "$target"
        fi
    done

    bash "$DOTFILES/install/opencode-config.sh" || exit 1

    bash "$DOTFILES/install/agent-instructions.sh" || exit 1

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

    echo -e "\n\nCreating zshrc symlinks"
    echo "=============================="
    ZSHRC=("$HOME/.zshrc:$DOTFILES/zsh/zshrc.symlink")
    for file in "${ZSHRC[@]}"; do
        KEY=${file%%:*}
        VALUE=${file#*:}
        [ -L "$KEY" ] && [ ! -e "$KEY" ] && rm "$KEY"
        if [ -e "$KEY" ]; then
            echo "${KEY} already exists... skipping."
        else
            echo "Creating symlink for $KEY"
            ln -s "$VALUE" "$KEY"
        fi
    done
fi

[[ "$LINK_PHASE" == files ]] && exit 0

github_ssh_preflight >&2 || true

bash "$DOTFILES/install/tmux-plugins.sh" || LINK_FAILURE=1

# Ensure clitools repo is present before linking
GH_USER=$(github_owner || true)
CLITOOLS_DIR="$(clitools_dir)"
[ -d "$CLITOOLS_DIR" ] && echo "Using existing clitools checkout at $CLITOOLS_DIR"
if [ -z "${CLITOOLS_REPO_URL:-}" ]; then
    if [ -n "$GH_USER" ]; then
        CLITOOLS_REPO_URL="$(github_repo_url "${GH_USER}/clitools")"
    else
        echo "Warning: GitHub owner could not be determined (set DOTFILES_GITHUB_OWNER); skipping clitools clone"
        CLITOOLS_REPO_URL=""
    fi
fi
if [ -n "$CLITOOLS_REPO_URL" ] && [ ! -d "$CLITOOLS_DIR" ] && ! github_repo_accessible "$CLITOOLS_REPO_URL"; then
    echo "clitools is private or missing at $CLITOOLS_REPO_URL; skipping it (set CLITOOLS_REPO_URL to use your own)"
elif [ -n "$CLITOOLS_REPO_URL" ] && [ ! -d "$CLITOOLS_DIR" ]; then
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

echo -e "\n\nInstalling Claude Code profiles"
echo "=============================="
CLAUDE_PROFILES_STATUS=0
bash "$DOTFILES/install/claude-profiles.sh" || CLAUDE_PROFILES_STATUS=$?
case "$CLAUDE_PROFILES_STATUS" in
    0) ;;
    2) warning "Claude profile setup is incomplete; see the messages above." ;;
    *) echo "Claude profile setup failed; see the messages above."; LINK_FAILURE=1 ;;
esac

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

echo -e "\n\nEnsuring ~/.gitconfig-local link"
echo "=============================="
LOCAL_FILE="$HOME/.gitconfig-local"
CLITOOLS_DIR_DEFAULT="$CLITOOLS_DIR"
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

if [ "$PLAN_MANAGER_FAILURE" -ne 0 ] || [ "${LINK_FAILURE:-0}" -ne 0 ]; then
  echo "Dotfiles installation needs attention; see the diagnostics above."
  exit 1
fi
