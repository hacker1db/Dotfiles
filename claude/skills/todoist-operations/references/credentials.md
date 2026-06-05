# Todoist Credentials

Use the 1Password CLI (`op`) as the source of truth for the Todoist API token. The item name is:

```text
Todoist api
```

Do not ask the user to paste the token. Do not write the token to `~/.env`, repository files, logs, notes, or command output. Keep it in process memory or an environment variable scoped to the command being run.

## Shell Tools

Prefer this pattern for commands that need `TODOIST_API_TOKEN`:

```zsh
TODOIST_API_TOKEN="$(op item get "Todoist api" --reveal --format json | jq -r '.fields[] | select((.label // "" | test("(?i)(api|token|password|credential)")) or (.id // "" | test("(?i)(api|token|password|credential)"))) | .value' | head -n 1)" command-that-needs-token
```

If `op` is not signed in, run `op signin` interactively or ask the user to unlock 1Password. Do not fall back to asking for the raw token.

## Python Tools

Use `TODOIST_API_TOKEN` if already present. Otherwise call `op` and parse the JSON item, selecting a concealed/password/token-like field.

```python
import json
import os
import subprocess


def get_todoist_token():
    existing = os.environ.get("TODOIST_API_TOKEN")
    if existing:
        return existing

    raw = subprocess.check_output(
        ["op", "item", "get", "Todoist api", "--reveal", "--format", "json"],
        text=True,
    )
    item = json.loads(raw)
    for field in item.get("fields", []):
        key = " ".join(str(field.get(k, "")) for k in ("id", "label", "purpose")).lower()
        value = field.get("value")
        if value and any(marker in key for marker in ("api", "token", "password", "credential")):
            return value
    raise RuntimeError("Todoist api item did not expose an API token field")
```

## MCP, Agent, and External Tool Workflows

When a tool cannot directly invoke `op`, wrap the tool invocation from the shell with `TODOIST_API_TOKEN` set using the Shell Tools pattern. If a spawned agent needs Todoist access, explicitly instruct it to retrieve the token from 1Password item `Todoist api` through `op` and to avoid printing or storing the token.
