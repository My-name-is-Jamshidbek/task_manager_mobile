# FCM Notification Payload Contract

This document defines the supported structured data templates for push notifications and how the mobile client interprets them.

## Overview

The app expects **data messages** (or notification + data) containing a `type` field that maps to a predefined template. The client validates required variables and performs contextual navigation or exposes an action button.

All dynamic variables are sent flattened at the top level of the `data` payload (no nested JSON required for now).

## Supported Templates

| Type                   | Screen         | Required Vars                                            | Optional Vars   | Description                  |
| ---------------------- | -------------- | -------------------------------------------------------- | --------------- | ---------------------------- |
| task_assigned          | task_detail    | task_id, task_title, due_date                            |                 | User assigned to a task      |
| task_updated           | task_detail    | task_id, task_title, updated_by, changed_fields          |                 | Task fields updated          |
| task_comment_added     | task_detail    | task_id, task_title, author, comment_id, comment_preview |                 | New comment on task          |
| task_completed         | task_detail    | task_id, task_title, completed_by                        |                 | Task marked complete         |
| task_due_soon          | task_detail    | task_id, task_title, hours_left                          |                 | Upcoming due time            |
| task_overdue           | task_detail    | task_id, task_title, hours_over                          |                 | Task past due                |
| project_created        | project_detail | project_id, project_name                                 |                 | New project created          |
| project_status_changed | project_detail | project_id, project_name, old_status, new_status         |                 | Project status changed       |
| announcement           | announcement   | message                                                  | announcement_id | System-wide announcement     |
| app_update_android     | update         | version_name, version_code                               |                 | Android app update available |
| app_update_ios         | update         | version_name, build_number                               |                 | iOS app update available     |

## Example Payloads

### Task Assigned

```json
{
  "to": "<fcm_token>",
  "data": {
    "type": "task_assigned",
    "screen": "task_detail",
    "task_id": "4821",
    "task_title": "Prepare Q3 Budget",
    "due_date": "2025-09-20T14:00:00Z"
  },
  "notification": {
    "title": "New Task Assigned",
    "body": "Prepare Q3 Budget (due soon)"
  }
}
```

### Comment Added

```json
{
  "data": {
    "type": "task_comment_added",
    "screen": "task_detail",
    "task_id": "4821",
    "task_title": "Prepare Q3 Budget",
    "author": "Alice",
    "comment_id": "9912",
    "comment_preview": "I pushed the latest draft..."
  }
}
```

### Project Status Change

```json
{
  "data": {
    "type": "project_status_changed",
    "screen": "project_detail",
    "project_id": "105",
    "project_name": "Mobile Redesign",
    "old_status": "planning",
    "new_status": "in_progress"
  }
}
```

### App Update (Android)

```json
{
  "data": {
    "type": "app_update_android",
    "screen": "update",
    "version_name": "2.4.0",
    "version_code": "89"
  }
}
```

## Client Validation Behavior

1. `type` is resolved to an internal enum.
2. Required variables are checked; if missing, a warning is logged but the notification still displays.
3. `screen` can be omitted; a default is inferred per template.
4. The in-app notification includes a View action if actionable.
5. Tapping triggers navigation helper stubs (extend to real routes).

## Backend Implementation Notes

- Always send `type`.
- Prefer also sending `screen` (explicit intent) even if defaults exist.
- Keep variable names lowercase with underscores to match mobile parsing.
- Avoid nested JSON for now; if required in future, we can extend the parser.

## Future Extensions

- Localized dynamic text placeholders (e.g. server supplies per-locale message bodies).
- Deep link support for web/app parity.
- Batched change summaries for `task_updated` (array parsing support).

---

Maintained alongside `lib/core/notifications/notification_templates.dart`.
