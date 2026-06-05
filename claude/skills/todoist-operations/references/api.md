# Todoist API Reference

## Priority Levels

- `4` = P1, red, highest
- `3` = P2, orange
- `2` = P3, yellow
- `1` = P4, white, default

## Project IDs

These IDs are account-specific. Do not share this file publicly.

PARA structure:

- 1-Projects: `2359994569`
- 2-Areas: `2359994572`
- 3-Resources: `2359995015`

Active projects:

- Ship to Beach Dashboard: `2360927142`
- Sprint Execution: `2360927149`
- Inbox: `377445380`
- Daily Briefing: `6cvj7XgXH4w93WgX`
- Ideas Backlog: `2263875911`
- Everything AI Backlog: `2352252927`
- Admin: `2331010777`

## Python API Helper

```python
import json
import os
import subprocess
import urllib.error
import urllib.parse
import urllib.request
import uuid


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


_headers = {
    "Authorization": f"Bearer {get_todoist_token()}",
    "Content-Type": "application/json",
}


def _request(url, data=None, method=None):
    encoded = json.dumps(data).encode("utf-8") if data is not None else None
    req = urllib.request.Request(
        url,
        data=encoded,
        headers=_headers,
        method=method or ("POST" if encoded else "GET"),
    )
    try:
        with urllib.request.urlopen(req) as resp:
            body = resp.read()
            return json.loads(body) if body else {}
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"Todoist API error {e.code} on {url}: {body}") from None


def get_tasks(filter_str=None):
    url = "https://api.todoist.com/rest/v2/tasks"
    if filter_str:
        url += "?" + urllib.parse.urlencode({"filter": filter_str})
    return _request(url)


def get_task(task_id):
    return _request(f"https://api.todoist.com/rest/v2/tasks/{task_id}")


def get_comments(task_id):
    url = "https://api.todoist.com/rest/v2/comments?" + urllib.parse.urlencode({"task_id": task_id})
    return _request(url)


def extract_attachments_from_comments(comments):
    attachments = []
    for comment in comments:
        att = comment.get("attachment")
        if att:
            attachments.append({
                "type": att.get("resource_type", "unknown"),
                "url": att.get("file_url") or att.get("image") or att.get("url"),
                "filename": att.get("file_name"),
                "dimensions": (
                    f"{att.get('image_width')}x{att.get('image_height')}"
                    if att.get("image_width") else None
                ),
            })
    return attachments


def add_comment(task_id, content):
    if not content.startswith("cc: "):
        content = "cc: " + content
    return _request(
        "https://api.todoist.com/rest/v2/comments",
        data={"task_id": task_id, "content": content},
    )


def update_task(task_id, **kwargs):
    return _request(f"https://api.todoist.com/rest/v2/tasks/{task_id}", data=kwargs)


def complete_task(task_id):
    return _request(
        f"https://api.todoist.com/rest/v2/tasks/{task_id}/close",
        data={},
        method="POST",
    )


def create_task(content, **kwargs):
    return _request(
        "https://api.todoist.com/rest/v2/tasks",
        data={"content": content, **kwargs},
    )


def move_task(task_id, project_id):
    result = _request(
        "https://api.todoist.com/sync/v9/sync",
        data={
            "commands": [{
                "type": "item_move",
                "uuid": str(uuid.uuid4()),
                "args": {"id": task_id, "project_id": project_id},
            }]
        },
    )
    for cmd_uuid, outcome in result.get("sync_status", {}).items():
        if outcome != "ok":
            raise RuntimeError(f"move_task failed for command {cmd_uuid}: {outcome}")
    return result
```

## Operation Notes

REST API v2 cannot move tasks between projects. Use Sync API v9 `item_move`.

Remove due dates with:

```python
update_task(task_id, due_string="no date")
```

When adding automated comments, prefix with `cc: `.
