#!/usr/bin/env bash
# track.sh: Claude Code hook. Appends one event line per hook call to .agent/time/<session>.jsonl.
# Wire it to: SessionStart, UserPromptSubmit, PreToolUse, PostToolUse, Stop, Notification, SessionEnd.
# Must stay fast (SessionEnd has a short timeout) and must never block the agent: always exit 0.
input="$(cat)"
root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
PYCMD=()
for c in python3 python "py -3"; do
  if $c -c 'import sys' >/dev/null 2>&1; then read -r -a PYCMD <<<"$c"; break; fi
done
[[ ${#PYCMD[@]} -gt 0 ]] || exit 0
"${PYCMD[@]}" - "$root" "$input" <<'PY' 2>/dev/null || true
import json, os, sys, datetime
root, raw = sys.argv[1], sys.argv[2]
try: d = json.loads(raw)
except Exception: d = {}
ev = d.get("hook_event_name", "unknown")
kind = {
  "SessionStart": "start", "UserPromptSubmit": "prompt",
  "PreToolUse": "tool_start", "PostToolUse": "tool_end",
  "Stop": "stop", "SubagentStop": "activity",
  "SessionEnd": "end",
}.get(ev, "activity")
if ev == "Notification":
  # idle_prompt means the agent is waiting on a person
  kind = "idle" if "idle" in json.dumps(d).lower() or "waiting" in json.dumps(d).lower() else "activity"
ticket = ""
for p in (os.path.join(root, ".agent", "current-ticket"),):
  try: ticket = open(p).read().strip()
  except Exception: pass
sid = d.get("session_id", "nosession")
out_dir = os.path.join(root, ".agent", "time")
os.makedirs(out_dir, exist_ok=True)
rec = {"ts": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"),
       "agent": "claude", "session": sid, "event": kind, "ticket": ticket}
if d.get("tool_name"): rec["tool"] = d["tool_name"]
with open(os.path.join(out_dir, f"{sid}.jsonl"), "a") as f:
  f.write(json.dumps(rec) + "\n")
PY
exit 0
