#!/usr/bin/env bash
# Throwaway spike script (SP-1): prove schtasks create/query/delete from Git Bash
# running bash.exe with a git vault command, destination path with spaces.
# Usage: sp-1-schtasks-probe.sh [xml|excl|cmd]   (default: excl)
# Creates then deletes task "git-vault-sp1-probe". Windows only.
set -euo pipefail

method="${1:-excl}"
task="git-vault-sp1-probe"
tmp="$(mktemp -d)"
dest="$tmp/dest with spaces"
mkdir -p "$dest"
bash_win="$(cygpath -w "$(command -v bash)")"
script_win="$(cygpath -w "$tmp/run.sh")"
printf '#!/usr/bin/env bash\necho ran > "%s/ran.txt"\n' "$dest" > "$tmp/run.sh"

cleanup() {
  MSYS2_ARG_CONV_EXCL='*' schtasks.exe /Delete /TN "$task" /F >/dev/null 2>&1 || true
  rm -rf "$tmp"
}
trap cleanup EXIT

# Quoting layers: schtasks /TR value is one string; inner paths with spaces need
# literal double quotes, written \" for the schtasks arg.
case "$method" in
  excl)
    # cygpath -m gives C:/... (no backslashes for bash to eat); pass as a script arg, no -c quoting
    tr_val="\"$bash_win\" -l \"$(cygpath -m "$tmp/run.sh")\""
    MSYS2_ARG_CONV_EXCL='*' schtasks.exe /Create /TN "$task" /TR "$tr_val" \
      /SC DAILY /ST 03:00 /F
    ;;
  cmd)
    cmd_win="$(cygpath -w "$tmp/run.cmd")"
    printf '@echo off\r\n"%s" -l "%s"\r\n' "$bash_win" "$script_win" > "$tmp/run.cmd"
    MSYS2_ARG_CONV_EXCL='*' schtasks.exe /Create /TN "$task" /TR "\"$cmd_win\"" \
      /SC DAILY /ST 03:00 /F
    ;;
  xml)
    xml_win="$(cygpath -w "$tmp/task.xml")"
    cat > "$tmp/task.xml" <<EOF
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <Triggers><CalendarTrigger><StartBoundary>2030-01-01T03:00:00</StartBoundary>
    <ScheduleByDay><DaysInterval>1</DaysInterval></ScheduleByDay></CalendarTrigger></Triggers>
  <Actions><Exec><Command>$bash_win</Command><Arguments>-l "$script_win"</Arguments></Exec></Actions>
</Task>
EOF
    # schtasks /XML wants UTF-16
    iconv -f UTF-8 -t UTF-16 "$tmp/task.xml" > "$tmp/task16.xml"
    MSYS2_ARG_CONV_EXCL='*' schtasks.exe /Create /TN "$task" /XML "$(cygpath -w "$tmp/task16.xml")" /F
    ;;
  *) echo "unknown method" >&2; exit 2 ;;
esac

MSYS2_ARG_CONV_EXCL='*' schtasks.exe /Query /TN "$task" /V /FO LIST | grep -E 'Task To Run|TaskName|Status'
MSYS2_ARG_CONV_EXCL='*' schtasks.exe /Run /TN "$task"
for _ in 1 2 3 4 5 6 7 8 9 10; do [ -f "$dest/ran.txt" ] && break; sleep 1; done
[ -f "$dest/ran.txt" ] && echo "RAN OK (dest with spaces)" || { echo "task did not run" >&2; exit 1; }
MSYS2_ARG_CONV_EXCL='*' schtasks.exe /Delete /TN "$task" /F
if MSYS2_ARG_CONV_EXCL='*' schtasks.exe /Query /TN "$task" >/dev/null 2>&1; then
  echo "delete failed" >&2; exit 1
fi
echo "DELETED OK"
