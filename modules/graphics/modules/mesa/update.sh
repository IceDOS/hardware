#!/usr/bin/env nix-shell
#! nix-shell -i bash -p git curl jq nix gnutar

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PATCHES_DIR="$SCRIPT_DIR/patches"
RC_JSON="$SCRIPT_DIR/rc.json"
GIT_JSON="$SCRIPT_DIR/git.json"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Commits on mesa main before the git overlay is bumped. Without a floor every
# commit would rebuild the whole cache.
MIN_GIT_COMMITS="${MIN_GIT_COMMITS:-50}"

NIXPKGS_MESA_PATH="pkgs/development/libraries/mesa"
GITHUB_API="https://api.github.com/repos/NixOS/nixpkgs/contents"
GITLAB_ARCHIVE="https://gitlab.freedesktop.org/mesa/mesa/-/archive"
GITLAB_API="https://gitlab.freedesktop.org/api/v4/projects/mesa%2Fmesa"

info()  { echo "==> $1"; }
error() { echo "ERROR: $1" >&2; exit 1; }

# --- Sync patches from nixpkgs ---
sync_patches() {
  info "Syncing patches from nixpkgs..."
  mkdir -p "$PATCHES_DIR"

  local api_resp
  api_resp=$(curl -sf "$GITHUB_API/$NIXPKGS_MESA_PATH" 2>/dev/null) \
    || error "Failed to fetch nixpkgs mesa directory from GitHub API"

  local patch_urls
  patch_urls=$(echo "$api_resp" | jq -r '.[] | select(.name | endswith(".patch")) | .download_url')

  local new_count=0
  while IFS= read -r url; do
    [ -z "$url" ] && continue
    local name
    name=$(basename "$url")
    local dest="$PATCHES_DIR/$name"

    if [ -f "$dest" ]; then
      local tmp="$TMP_DIR/$name"
      curl -sf "$url" -o "$tmp" || { echo "  WARN: failed to download $name, skipping"; continue; }
      if ! cmp -s "$dest" "$tmp"; then
        info "  Updated: $name"
        cp "$tmp" "$dest"
        new_count=$((new_count + 1))
      fi
    else
      info "  New: $name"
      curl -sf "$url" -o "$dest" || { echo "  WARN: failed to download $name, skipping"; continue; }
      new_count=$((new_count + 1))
    fi
  done <<< "$patch_urls"

  # Remove local patches no longer in nixpkgs
  for existing in "$PATCHES_DIR"/*.patch; do
    [ -f "$existing" ] || continue
    local basename
    basename=$(basename "$existing")
    if ! echo "$patch_urls" | grep -qF "$basename"; then
      info "  Removed stale: $basename"
      rm "$existing"
    fi
  done

  if [ "$new_count" -eq 0 ]; then
    info "  Patches up to date."
  fi
}

# --- Compute SRI hash for a source tarball ---
compute_hash() {
  local path="$1"
  local file_url="file://$path"
  local nar_hash
  nar_hash=$(nix-prefetch-url --unpack --type sha256 "$file_url" 2>/dev/null | tail -1)
  nix hash to-sri --type sha256 "$nar_hash" 2>/dev/null | grep -v '^warning:' || echo "$nar_hash"
}

# --- Write a {version, rev, hash} overlay pin ---
write_pin() {
  local file="$1" version="$2" rev="$3" hash="$4"
  jq -n --arg version "$version" --arg rev "$rev" --arg hash "$hash" \
    '{version: $version, rev: $rev, hash: $hash}' > "$file"
}

# --- Update RC overlay ---
update_rc() {
  info "Finding latest mesa RC tag..."

  local tags
  tags=$(git ls-remote --tags https://gitlab.freedesktop.org/mesa/mesa.git 2>/dev/null) \
    || error "Failed to list mesa tags"

  local latest_rc
  latest_rc=$(echo "$tags" \
    | grep -oP 'refs/tags/mesa-\K[0-9]+\.[0-9]+\.[0-9]+-rc[0-9]+$' \
    | sort -V | tail -1)

  [ -z "$latest_rc" ] && error "No RC tags found"
  info "  Latest RC: $latest_rc"

  # A final release supersedes its own RCs. The $ anchors matter -- without them
  # the "final" pattern also matches the release part of an -rcN tag.
  local latest_final rc_base
  latest_final=$(echo "$tags" \
    | grep -oP 'refs/tags/mesa-\K[0-9]+\.[0-9]+\.[0-9]+$' \
    | sort -V | tail -1)
  rc_base="${latest_rc%%-rc*}"
  if [ -n "$latest_final" ] \
    && [ "$(printf '%s\n%s\n' "$rc_base" "$latest_final" | sort -V | head -1)" = "$rc_base" ]; then
    info "  WARNING: RC $latest_rc superseded by final release $latest_final (mesa.rc falls back to nixpkgs mesa)"
  fi

  local tag="mesa-$latest_rc"
  local current_rev
  current_rev=$(jq -r '.rev // ""' "$RC_JSON" 2>/dev/null || echo "")

  if [ "$tag" = "$current_rev" ]; then
    info "  RC already up to date ($tag)"
    return
  fi

  local tarball_url="$GITLAB_ARCHIVE/$tag/$tag.tar.gz"
  info "  Current: $current_rev"
  info "  Downloading $tarball_url ..."
  curl -sf "$tarball_url" -o "$TMP_DIR/rc.tar.gz" || error "Failed to download RC tarball"

  info "  Computing hash..."
  local hash
  hash=$(compute_hash "$TMP_DIR/rc.tar.gz")
  info "  Hash: $hash"
  write_pin "$RC_JSON" "$latest_rc" "$tag" "$hash"
  info "  RC updated: $latest_rc"
}

# --- Update git overlay ---
update_git() {
  info "Finding latest mesa main branch commit..."

  local git_rev
  git_rev=$(git ls-remote --heads https://gitlab.freedesktop.org/mesa/mesa.git main 2>/dev/null \
    | awk '{print $1}')

  [ -z "$git_rev" ] && error "Could not fetch main branch HEAD"
  info "  Latest main: $git_rev"

  local current_rev
  current_rev=$(jq -r '.rev // ""' "$GIT_JSON" 2>/dev/null || echo "")

  if [ "$git_rev" = "$current_rev" ]; then
    info "  Git already up to date ($git_rev)"
    return
  fi

  # Fail open: if the count cannot be determined (API error, current_rev gone,
  # first-ever seed) we bump.
  if [ -n "$current_rev" ]; then
    local count
    count=$(curl -sf "$GITLAB_API/repository/compare?from=${current_rev}&to=${git_rev}&straight=true" 2>/dev/null \
              | jq -r '.commits | length' 2>/dev/null || echo "")
    if [[ "$count" =~ ^[0-9]+$ ]]; then
      if [ "$count" -lt "$MIN_GIT_COMMITS" ]; then
        info "  Only $count new commit(s) since $current_rev (< $MIN_GIT_COMMITS); skipping git bump"
        return
      fi
      info "  $count new commit(s) since current pin (>= $MIN_GIT_COMMITS)"
    else
      info "  Could not determine commit distance; bumping anyway"
    fi
  fi

  local tarball_url="$GITLAB_ARCHIVE/$git_rev/mesa-$git_rev.tar.gz"
  info "  Current: $current_rev"
  info "  Downloading $tarball_url ..."
  curl -sf "$tarball_url" -o "$TMP_DIR/git.tar.gz" || error "Failed to download git tarball"

  info "  Computing hash..."
  local hash
  hash=$(compute_hash "$TMP_DIR/git.tar.gz")
  info "  Hash: $hash"

  # VERSION lands in the derivation name, so gate it to a safe charset. Anything
  # missing, unreadable or unsafe falls through to the short-rev warning below.
  local git_version version
  git_version=$(tar -xzOf "$TMP_DIR/git.tar.gz" --wildcards --no-wildcards-match-slash '*/VERSION' 2>/dev/null | head -1 | tr -d '\r' || true)
  if [[ "$git_version" =~ ^[A-Za-z0-9._+-]+$ ]]; then
    version="${git_version}-${git_rev:0:7}"
  else
    version="${git_rev:0:7}"
    info "  WARNING: could not read a usable VERSION from source; using bare short rev $version"
  fi
  write_pin "$GIT_JSON" "$version" "$git_rev" "$hash"
  info "  Git updated: $version"
}

# --- Main ---
main() {
  echo "Mesa overlay updater"
  echo "===================="

  sync_patches
  update_rc
  update_git

  echo ""
  info "Done. Review changes with: git diff $SCRIPT_DIR"
}

main "$@"
