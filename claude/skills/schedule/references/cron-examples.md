# Schedule — Cron & Timing Reference

## Cron Expression Format

```
minute  hour  day-of-month  month  day-of-week
  0      9        *           *       1-5
```

All times are in the **user's LOCAL timezone**, not UTC.

## Common Patterns

| Schedule | cronExpression |
|----------|---------------|
| Every day at 9 AM | `0 9 * * *` |
| Weekdays at 9 AM | `0 9 * * 1-5` |
| Every Monday at 8:30 AM | `30 8 * * 1` |
| Every Friday at 5 PM | `0 17 * * 5` |
| First day of month at midnight | `0 0 1 * *` |
| Every hour | `0 * * * *` |
| Every 30 minutes | `*/30 * * * *` |
| Twice daily (9 AM and 5 PM) | `0 9,17 * * *` |
| Weekdays at 6 AM and 6 PM | `0 6,18 * * 1-5` |

## Day of Week Values

| Value | Day |
|-------|-----|
| 0 or 7 | Sunday |
| 1 | Monday |
| 2 | Tuesday |
| 3 | Wednesday |
| 4 | Thursday |
| 5 | Friday |
| 6 | Saturday |

## One-Time Fires (fireAt)

Use ISO 8601 with timezone offset. The task auto-disables after firing.

```
2026-03-20T14:30:00-08:00   →  March 20, 2026 at 2:30 PM Pacific
2026-03-20T09:00:00-05:00   →  March 20, 2026 at 9:00 AM Eastern
2026-03-20T17:00:00+00:00   →  March 20, 2026 at 5:00 PM UTC
```

To compute "in 5 minutes": take current time (from `<env>` block) + 5 minutes, emit with timezone.

## Choosing a Schedule

| User says | Interpretation |
|-----------|---------------|
| "every morning" | `0 9 * * *` — propose 9 AM, ask to confirm time |
| "weekdays" | `0 9 * * 1-5` — propose 9 AM weekdays |
| "remind me in 5 minutes" | `fireAt` = now + 5 min |
| "tomorrow at 3pm" | `fireAt` = tomorrow 15:00 with user's tz offset |
| "run this whenever I ask" | ad-hoc — omit both fields |
| "every hour during business hours" | `0 9-17 * * 1-5` |
