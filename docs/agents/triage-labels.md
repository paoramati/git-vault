# Triage Labels

The skills speak in terms of five canonical triage roles. This file maps them to the label strings used in this repo's tracker (beads).

| Label in mattpocock/skills | Label in our tracker | Meaning                                  |
| -------------------------- | -------------------- | ---------------------------------------- |
| `needs-triage`             | `needs-triage`       | Maintainer needs to evaluate this issue  |
| `needs-info`               | `needs-info`         | Waiting on reporter for more information |
| `ready-for-agent`          | `agent-ok`           | Fully specified, ready for an AFK agent  |
| `ready-for-human`          | `human-only`         | Requires human implementation            |
| `wontfix`                  | `wontfix`            | Will not be actioned                     |

When a skill mentions a role (for example "apply the AFK-ready triage label"), use the label string from this table. The factory loop picks up only tickets labelled `agent-ok`.
