# Plan Server Reference

## Stable local dashboard URL

```
http://plans.localhost:4173/
```

Plans are accessible at stable ID-based routes:
```
http://plans.localhost:4173/plans/<id>
```

The ID is immutable. Title changes, filename normalization, status changes, and archive moves do not change the plan URL.

## Service health workflow

Before any open or review operation, verify the service is running:

```
plan serve --json   # idempotent: starts if stopped, no-op if already running
plan doctor --json  # validate storage, port, LaunchAgent, and dashboard health
```

If `plan doctor` reports `serviceState: "error"`, surface the diagnostic output and do not claim the dashboard URL is reachable.

If `plan doctor` reports a port collision on 4173, report the owning process information from the output and do not attempt to start an independent server.

## Automatic startup

A macOS LaunchAgent runs `plan serve --foreground` at login with `RunAtLoad` and `KeepAlive`. The service is normally available without manual intervention after the first login following `install/link.sh`.

## Same-page refresh

The server publishes monotonic revision events over a same-origin Server-Sent Events endpoint. When the open plan's revision changes, the browser reloads its current URL without navigating away. Library-list pages refresh their data in place. Unrelated plan changes do not interrupt an open plan detail view.

After reconnection or computer wake, the client compares the last known revision with the current server revision and reloads the same page if it became stale.

## Offline use

The dashboard uses local CSS and no remote font or CDN dependencies. It remains fully styled and functional without internet access.

## Port collision

The server uses a fixed port. If port 4173 is occupied, `plan serve` and `plan doctor` report the collision and the owning process instead of silently changing the URL. Resolve the collision before starting the service.

## Failure reporting

When the service cannot be started or reached:
- Report the exact error from `plan doctor --json`
- Do not fabricate a dashboard URL
- Do not start an independent HTTP server
- Do not edit canonical Markdown files as a fallback

## Fallback host

The server also accepts `127.0.0.1` as a fallback host and binds only to `127.0.0.1`. All mutating requests require same-origin checks and a session CSRF token.
