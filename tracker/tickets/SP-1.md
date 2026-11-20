---
id: SP-1
title: How should git-vault call Task Scheduler from Git Bash?
type: spike
status: ready
priority: 0
parent: E-1
labels: [agent-ok]
question: What exact schtasks.exe invocation from Git Bash creates, queries and deletes a task that runs Git Bash's bash.exe with a git vault command, given MSYS path conversion and paths with spaces?
timebox_hours: 2
decision_record: docs/decisions/0001-task-scheduler-from-git-bash.md
external_ref: ""
time:
  active_seconds: 0
  sessions: []
---

## Options to consider
- schtasks.exe with MSYS2_ARG_CONV_EXCL and cygpath -w paths
- schtasks.exe /XML with a generated task XML file
- a tiny generated .cmd wrapper that the task runs

## Output
The decision record, plus a throwaway script in docs/decisions/ proving create, query and delete work, including a destination path with spaces. Note anything that cannot be tested in CI.
