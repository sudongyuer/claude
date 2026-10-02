---
argument-hint: "[receiving agent] [optional focus]"
description: Write a self-contained handoff prompt so another agent or a fresh session can continue this work
---

Use the `session-handoff` skill to produce a handoff document for the current session.

- Receiving agent and focus: `$ARGUMENTS` (if empty, write for a fresh Claude Code session continuing the current task).
- Follow the skill's required sections and writing rules; redact secrets.
- Write it to a file as the skill describes and reply with the path plus one line naming the receiver and the goal.
- Do not start the receiving agent yourself.
