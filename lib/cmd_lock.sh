# git vault lock: disable pushing with two independent layers.
#  1. every remote's pushurl is replaced with an invalid URL (originals saved under
#     vault.<remote>.pushurl), plus url.<invalid>.pushInsteadOf="" to catch remotes
#     added later and raw URLs.
#  2. a pre-push hook that refuses. A user's own hook is moved to pre-push.vault-orig.
# Sourced by the git-vault entrypoint.

cmd_lock() {
  require_repo
  local r v hooks hook orig
  while IFS= read -r r; do
    [[ -n "$r" ]] || continue
    if ! git config --get "vault.$r.saved" >/dev/null 2>&1; then
      # First lock of this remote: save the original push config. Never overwritten.
      while IFS= read -r v; do
        git config --add "vault.$r.pushurl" "$v"
      done < <(git config --get-all "remote.$r.pushurl" || true)
      git config "vault.$r.saved" true
    fi
    git config --replace-all "remote.$r.pushurl" "$VAULT_LOCK_URL"
  done < <(git remote)
  git config --replace-all "url.$VAULT_LOCK_URL.pushInsteadOf" ""

  hooks="$(vault_hooks_dir)"; hook="$hooks/pre-push"; orig="$hooks/pre-push.vault-orig"
  mkdir -p "$hooks"
  if [[ -e "$hook" ]] && ! grep -qF "$VAULT_HOOK_MARK" "$hook"; then
    [[ ! -e "$orig" ]] || die "cannot lock: $orig already exists; resolve it first"
    mv "$hook" "$orig"
  fi
  printf '#!/bin/sh\n%s\necho "git-vault: pushing is locked; run git vault unlock" >&2\nexit 1\n' \
    "$VAULT_HOOK_MARK" > "$hook"
  chmod +x "$hook"
  echo "locked: pushing disabled"
}
