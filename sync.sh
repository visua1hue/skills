#!/usr/bin/env bash
set -euo pipefail

MANIFEST="$(dirname "$0")/MANIFEST.yaml"
REPO_DIR="$(dirname "$0")"

parse_yaml_field() {
  local skill="$1" field="$2"
  awk "/^  ${skill}:/{found=1} found && /^    ${field}:/{print \$2; exit}" "$MANIFEST"
}

update_manifest_field() {
  local skill="$1" field="$2" value="$3"
  sed -i '' "/^  ${skill}:/,/^  [^ ]/ s|^    ${field}: .*|    ${field}: ${value}|" "$MANIFEST"
}

sync_skill() {
  local skill="$1" apply="${2:-}"
  local url
  url="$(parse_yaml_field "$skill" "url")"

  if [[ -z "$url" || "$url" == "~" ]]; then
    echo "[$skill] no upstream URL in MANIFEST — skipping"
    return
  fi

  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT

  echo "[$skill] fetching $url ..."
  curl -fsSL "$url" -o "$tmp/SKILL.md"

  local local_file="$REPO_DIR/$skill/SKILL.md"
  if [[ ! -f "$local_file" ]]; then
    echo "[$skill] no local SKILL.md found at $local_file"
    return
  fi

  if diff -u "$local_file" "$tmp/SKILL.md"; then
    echo "[$skill] up to date"
  else
    if [[ "$apply" == "--apply" ]]; then
      cp "$tmp/SKILL.md" "$local_file"
      local today sha
      today="$(date +%Y-%m-%d)"
      sha="$(curl -fsSL "$url" | shasum -a 256 | awk '{print $1}')"
      update_manifest_field "$skill" "last_synced" "$today"
      update_manifest_field "$skill" "sha" "$sha"
      echo "[$skill] applied — MANIFEST updated"
    fi
  fi
}

TARGET="${1:-}"
APPLY="${2:-}"

if [[ -z "$TARGET" ]]; then
  upstreams="$(awk '/^  [a-z]/{gsub(/:/, ""); print $1}' "$MANIFEST")"
  for skill in $upstreams; do
    sync_skill "$skill"
  done
else
  sync_skill "$TARGET" "$APPLY"
fi
