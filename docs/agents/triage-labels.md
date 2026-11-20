# Triage Labels

The skills speak in terms of five canonical triage roles. This file maps them to the label strings used in this repo's tracker (GitHub Issues). They are the same strings.

| Label in mattpocock/skills | Label in our tracker | Meaning                                  |
| -------------------------- | -------------------- | ---------------------------------------- |
| `needs-triage`             | `needs-triage`       | Maintainer needs to evaluate this issue  |
| `needs-info`               | `needs-info`         | Waiting on reporter for more information |
| `ready-for-agent`          | `ready-for-agent`    | Fully specified, ready for an AFK agent  |
| `ready-for-human`          | `ready-for-human`    | Requires human implementation            |
| `wontfix`                  | `wontfix`            | Will not be actioned                     |

The factory loop picks up only open issues labelled `ready-for-agent` whose blockers are closed, and adds `in-progress` while it works one. A ticket that fails twice is handed back by swapping `ready-for-agent` for `ready-for-human`.
