#!/usr/bin/env bash
# install.sh: copy git-vault onto PATH so `git vault` works.
# Usage: ./install.sh [target-dir]   (default: ~/bin, which Git Bash puts on PATH)
set -euo pipefail
src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/git-vault"
target="${1:-$HOME/bin}"
mkdir -p "$target"
cp "$src" "$target/git-vault"
chmod +x "$target/git-vault"
echo "installed $target/git-vault"
case ":$PATH:" in
  *":$target:"*) ;;
  *) echo "note: $target is not on PATH in this shell; open a new Git Bash window or add it to PATH" ;;
esac
git vault version
