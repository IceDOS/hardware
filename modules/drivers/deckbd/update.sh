#!/usr/bin/env nix-shell
#! nix-shell -i bash -p curl git jq nix nix-prefetch-git

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
CORE="${ICEDOS_CORE:-$REPO_ROOT/.icedos-core}"
[ -d "$CORE" ] || CORE="$REPO_ROOT/../core"
[ -f "$CORE/lib/update-lib.sh" ] || {
  echo "ERROR: core not found; set ICEDOS_CORE=/path/to/IceDOS/core" >&2
  exit 1
}
# shellcheck source=/dev/null
. "$CORE/lib/update-lib.sh"

PIN="$SCRIPT_DIR/source.json"
REPO="ninlives/deckbd"
BRANCH="main"

main() {
  banner "deckbd updater"

  info "Finding latest $REPO $BRANCH commit..."
  local rev
  rev=$(git_head "https://github.com/$REPO" "$BRANCH")
  [ -n "$rev" ] || error "could not read $BRANCH HEAD"
  info "  Latest: $rev"

  local current
  current=$(read_pin "$PIN" .rev)
  if [ "$rev" = "$current" ]; then
    info "  Already up to date ($rev)"
    return
  fi
  info "  Current: ${current:-none}"

  # One clone yields both the hash and the commit date, so no GitHub API call is needed
  # and an exhausted unauthenticated rate limit cannot break the run.
  info "  Computing hash..."
  local report hash date version
  report=$(prefetch_git_json "https://github.com/$REPO" "$rev" || echo "")
  hash=$(echo "$report" | jq -r '.hash // ""')
  date=$(echo "$report" | jq -r '.date // ""' | cut -d'T' -f1)

  # Upstream has never tagged, so the version is the commit date in nixpkgs'
  # `unstable-<date>` form — it still orders correctly for version comparisons.
  version="unstable-$date"

  require_nonempty deckbd "$date" "$rev" "$hash"
  info "  Hash: $hash"

  jq -n --arg version "$version" --arg rev "$rev" --arg hash "$hash" \
    '{version: $version, rev: $rev, hash: $hash}' | write_pin "$PIN"

  info "  Updated: $version ($rev)"
}

main "$@"

echo ""
info "Done. Review changes with: git diff $SCRIPT_DIR"
