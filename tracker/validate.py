#!/usr/bin/env python3
"""validate.py: check Markdown ticket frontmatter against schema.json.

Usage: validate.py <tickets-dir> [schema.json]
Needs PyYAML and jsonschema (pip install pyyaml jsonschema). Exits 1 on any invalid ticket.
"""
import glob, json, os, re, sys

try:
    import yaml, jsonschema
except ImportError:
    sys.exit("validate.py needs: pip install pyyaml jsonschema")

tickets_dir = sys.argv[1] if len(sys.argv) > 1 else "tracker/tickets"
schema_path = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(__file__), "schema.json")
schema = json.load(open(schema_path))
validator = jsonschema.Draft202012Validator(schema)

files = sorted(glob.glob(os.path.join(tickets_dir, "*.md")))
if not files:
    print(f"no tickets in {tickets_dir}")
    sys.exit(0)

bad = 0
for path in files:
    text = open(path).read()
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        print(f"FAIL {path}: no frontmatter"); bad += 1; continue
    data = yaml.safe_load(m.group(1)) or {}
    errors = sorted(validator.iter_errors(data), key=lambda e: list(e.path))
    stem = os.path.splitext(os.path.basename(path))[0]
    if data.get("id") != stem:
        errors.append(type("E", (), {"message": f"id '{data.get('id')}' does not match file name '{stem}'", "path": []})())
    if errors:
        bad += 1
        for e in errors:
            loc = "/".join(str(p) for p in e.path) or "(root)"
            print(f"FAIL {path} [{loc}]: {e.message}")
    else:
        print(f"ok   {path}")
sys.exit(1 if bad else 0)
