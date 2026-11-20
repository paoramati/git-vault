#!/usr/bin/env bash
# import-to-beads.sh: create beads issues from tracker/tickets/*.md.
#
# Usage: tracker/import-to-beads.sh [--dry-run]
#   --dry-run   print the bd commands instead of running them (do this first)
#
# Mapping: beads has native types epic/feature/bug/task/chore. mechanic, spike, standard
# and workflow become type "task" with a type:<name> label. The file's id is kept as the
# label src:<id> so the mapping to beads IDs can be looked up later.
# The full ticket file (frontmatter and body) becomes the beads description, so agents
# see acceptance criteria and invariants with `bd show`.
#
# Flags used: bd create --title/-t/-p/-d/-l --json, bd dep add <issue> <depends-on>.
# Flags checked against bd 1.3.4 on 2026-11-20.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
dry=0; [[ "${1:-}" == "--dry-run" ]] && dry=1

PYCMD=()
for c in python3 python "py -3"; do
  if $c -c 'import sys' >/dev/null 2>&1; then read -r -a PYCMD <<<"$c"; break; fi
done
[[ ${#PYCMD[@]} -gt 0 ]] || { echo "No working Python found." >&2; exit 1; }

"${PYCMD[@]}" - "$dry" <<'PY'
import glob, json, os, re, shutil, subprocess, sys
dry = sys.argv[1] == "1"
try:
    import yaml
except ImportError:
    sys.exit("needs pyyaml: pip install pyyaml")

BD = shutil.which("bd") or sys.exit("bd not found on PATH")
native = {"epic", "feature", "bug", "task", "chore"}
tickets = []
path_of = {}  # bd treats a -d value starting with "---" as a flag, so pass files
for path in sorted(glob.glob("tracker/tickets/*.md")):
    text = open(path, encoding="utf-8").read()
    fm = yaml.safe_load(re.match(r"^---\n(.*?)\n---\n", text, re.S).group(1))
    tickets.append((fm, text))
    path_of[fm["id"]] = path

# epics first, then by priority, so parents exist before children
tickets.sort(key=lambda t: (t[0]["type"] != "epic", t[0].get("priority", 2), t[0]["id"]))
ids = {}

def run(cmd):
    if dry:
        print(" ".join(json.dumps(c) if " " in c or "\n" in c else c for c in cmd)[:200] + (" ..." if len(" ".join(cmd)) > 200 else ""))
        return {"id": "bd-" + cmd[cmd.index("-l") + 1].split(",")[0].split(":")[1] if "-l" in cmd else "x"}
    out = subprocess.run(cmd, capture_output=True, text=True, check=True).stdout
    try:
        return json.loads(out[out.index("{"):])  # skip any notice text before the JSON
    except (ValueError, json.JSONDecodeError):
        m = re.search(r"Created issue: (\S+)", out)  # bd prints text when the description is long
        if m:
            return {"id": m.group(1)}
        print(f"unparseable bd output: {out[:300]!r}", file=sys.stderr)
        return {}

for fm, text in tickets:
    t = fm["type"]
    labels = [f"src:{fm['id']}"] + list(fm.get("labels", []))
    if t not in native:
        labels.append(f"type:{t}")
    cmd = [BD, "create", fm["title"],
           "-t", t if t in native else "task",
           "-p", str(fm.get("priority", 2)),
           "--body-file", path_of[fm["id"]],
           "-l", ",".join(labels),
           "--json"]
    res = run(cmd)
    bid = res.get("id") or (res.get("issue") or {}).get("id")
    if not bid:
        sys.exit(f"could not read the new issue id for {fm['id']}; check bd create --json output")
    ids[fm["id"]] = bid
    print(f"{fm['id']} -> {bid}", file=sys.stderr)

for fm, _ in tickets:
    deps = list(fm.get("depends_on", []) or [])
    if fm.get("parent"):
        deps_parent = fm["parent"]
        run([BD, "dep", "add", ids[fm["id"]], ids[deps_parent], "--type", "parent-child"])
    for d in deps:
        run([BD, "dep", "add", ids[fm["id"]], ids[d]])

if not dry:
    with open("tracker/beads-id-map.json", "w") as f:
        json.dump(ids, f, indent=2)
    print("wrote tracker/beads-id-map.json", file=sys.stderr)
PY
