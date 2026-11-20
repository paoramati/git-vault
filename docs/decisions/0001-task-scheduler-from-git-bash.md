# 0001: Calling Task Scheduler from Git Bash

Status: accepted (SP-1, spike gv-92d)

## Decision

Use `schtasks.exe` directly with `MSYS2_ARG_CONV_EXCL='*'` set for that call only, and build every path with `cygpath`. Task action:

```bash
bash_win="$(cygpath -w "$(command -v bash)")"      # C:\Program Files\Git\usr\bin\bash.exe
script="$(cygpath -m "$path_to_script")"           # C:/... forward slashes
MSYS2_ARG_CONV_EXCL='*' schtasks.exe /Create /TN "$name" \
  /TR "\"$bash_win\" -l \"$script\"" /SC DAILY /ST 03:00 /F
MSYS2_ARG_CONV_EXCL='*' schtasks.exe /Query  /TN "$name" /V /FO LIST
MSYS2_ARG_CONV_EXCL='*' schtasks.exe /Delete /TN "$name" /F
```

- Run `git vault backup` via a small generated script (or `-l -c` with args that contain no backslashes). Keep the git-vault path as a script arg, not inside `-c '...'`.
- Absolute bash path is required: Task Scheduler's PATH has no Git Bash.
- `-l` (login shell) so git and coreutils are on PATH.

## Evidence (`sp-1-schtasks-probe.sh`, run on Windows 11, Git for Windows)

| Method                                           | Create | Query | Run | Delete | Notes                                                                                                                                                     |
| ------------------------------------------------ | ------ | ----- | --- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `schtasks /TR` + `MSYS2_ARG_CONV_EXCL` + cygpath | ok     | ok    | ok  | ok     | Chosen. Query shows exact command. Dest path with spaces worked.                                                                                          |
| generated `.cmd` wrapper                         | ok     | ok    | ok  | ok     | Works; extra file to create and clean up, CRLF needed. Fallback.                                                                                          |
| `/XML`                                           | fail   |       |     |        | "task XML is malformed" with `iconv -t UTF-16`. Fixable (BOM/LE) but heaviest; only worth it for settings `schtasks` flags lack (run-if-missed, battery). |

Findings:

- Without `MSYS2_ARG_CONV_EXCL`, `/Create`, `/TN` etc. are mangled as POSIX paths. Set it per call, not globally.
- `-lc "'/tmp/x/run.sh'"` worked but stored doubled quotes (`""/tmp/..""`) and relies on MSYS `/tmp` mapping. Avoid; use `cygpath -m` path as a script argument.
- Backslash paths inside `bash -c` strings get eaten; hence `cygpath -m` for the script.
- `/TR` limit is 261 characters; keep the generated command short (use a wrapper script path under the vault dir if needed). Not tested.
- Delete must be idempotent: ignore failure when the task does not exist, but verify via `/Query`.

## Cannot be tested in CI

- Anything touching the real Task Scheduler (needs Windows, mutates machine state). Tests should stub `schtasks.exe` on PATH with a fake that records argv, and assert the exact arguments. Real create/run/delete only via manual run of the probe script.
- Behaviour when the user is logged off, on battery, or the machine is asleep (`/RU`, `/RL`, run-if-missed). Not tested; `/XML` needed for run-if-missed.
- Non-admin vs elevated: probe ran as a normal user with a per-user task (no `/RU`), which worked.
- Localised `schtasks` output (query text parsing); parse with `/FO CSV` or check exit code instead.
