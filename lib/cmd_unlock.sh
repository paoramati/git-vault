# git vault unlock: undo cmd_lock, restoring the exact original push config and hook.
# Sourced by the git-vault entrypoint.

cmd_unlock() {
  require_repo
  local key r v hooks hook orig
  while IFS= read -r key; do
    [[ -n "$key" ]] || continue
    r="${key#vault.}"; r="${r%.saved}"
    git config --unset-all "remote.$r.pushurl" 2>/dev/null || true
    while IFS= read -r v; do
      git config --add "remote.$r.pushurl" "$v"
    done < <(git config --get-all "vault.$r.pushurl" || true)
    git config --remove-section "vault.$r" 2>/dev/null || true
  done < <(git config --get-regexp '^vault\..*\.saved$' | cut -d' ' -f1 || true)
  git config --remove-section "url.$VAULT_LOCK_URL" 2>/dev/null || true

  hooks="$(vault_hooks_dir)"; hook="$hooks/pre-push"; orig="$hooks/pre-push.vault-orig"
  if [[ -e "$hook" ]]; then
    if grep -qF "$VAULT_HOOK_MARK" "$hook"; then
      rm -f "$hook"
      [[ ! -e "$orig" ]] || mv "$orig" "$hook"
    else
      echo "git-vault: warning: pre-push hook was replaced while locked; leaving it" >&2
      [[ ! -e "$orig" ]] || echo "git-vault: warning: original hook kept at $orig" >&2
    fi
  elif [[ -e "$orig" ]]; then
    mv "$orig" "$hook"
  fi
  echo "unlocked: pushing restored"
}
