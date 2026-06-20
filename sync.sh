#!/usr/bin/env bash
set -euo pipefail

MANIFEST="$(dirname "$0")/MANIFEST.yaml"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

parse_field() {
  local skill="$1" field="$2"
  awk "/^  ${skill}:/{f=1} f && /^    ${field}:/{sub(/^    ${field}: /, \"\"); print; exit}" "$MANIFEST"
}

update_field() {
  local skill="$1" field="$2" value="$3"
  sed -i '' "/^  ${skill}:/,/^  [^ ]/ s|^    ${field}: .*|    ${field}: ${value}|" "$MANIFEST"
}

list_upstreams() {
  awk '/^  [a-z][a-z-]*:/{gsub(/:/, ""); print $1}' "$MANIFEST"
}

fetch_file_list() {
  local repo="$1" path="$2" ref="$3"
  curl -fsSL "https://api.github.com/repos/${repo}/git/trees/${ref}?recursive=1" \
    | python3 -c "
import json, sys
data = json.load(sys.stdin)
prefix = '${path}/'
for item in data.get('tree', []):
    if item['type'] == 'blob' and item['path'].startswith(prefix) and item['path'].endswith('.md'):
        print(item['path'][len(prefix):])
"
}

fetch_tree_sha() {
  local repo="$1" ref="$2"
  curl -fsSL "https://api.github.com/repos/${repo}/git/trees/${ref}?recursive=1" \
    | python3 -c "import json,sys; print(json.load(sys.stdin).get('sha','~'))"
}

sync_skill() {
  local skill="$1" apply="${2:-}"

  local repo path ref
  repo="$(parse_field "$skill" "repo")"
  path="$(parse_field "$skill" "path")"
  ref="$(parse_field "$skill" "ref")"

  if [[ -z "$repo" || "$repo" == "~" ]]; then
    echo "[$skill] no repo in MANIFEST — skipping"
    return
  fi

  local tmp
  tmp="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf ${tmp}" EXIT

  echo "[$skill] fetching from upstream ${repo}@${ref}..."

  local files
  files="$(fetch_file_list "$repo" "$path" "$ref")"

  if [[ -z "$files" ]]; then
    echo "[$skill] no files found at ${path}"
    return
  fi

  local has_diff=false

  while IFS= read -r rel; do
    local raw_url="https://raw.githubusercontent.com/${repo}/${ref}/${path}/${rel}"
    local local_file="${REPO_DIR}/${skill}/${rel}"
    local tmp_file="${tmp}/${rel}"

    mkdir -p "$(dirname "$tmp_file")"
    curl -fsSL "$raw_url" -o "$tmp_file"

    if [[ ! -f "$local_file" ]]; then
      echo "  [new]     ${rel}"
      has_diff=true
      if [[ "$apply" == "--apply" ]]; then
        mkdir -p "$(dirname "$local_file")"
        cp "$tmp_file" "$local_file"
      fi
    elif ! diff -q "$local_file" "$tmp_file" > /dev/null 2>&1; then
      echo "  [changed] ${rel}"
      diff -u "$local_file" "$tmp_file" || true
      has_diff=true
      if [[ "$apply" == "--apply" ]]; then
        cp "$tmp_file" "$local_file"
      fi
    fi
  done <<< "$files"

  if ! $has_diff; then
    echo "[$skill] up to date"
    return
  fi

  if [[ "$apply" == "--apply" ]]; then
    local sha today
    sha="$(fetch_tree_sha "$repo" "$ref")"
    today="$(date +%Y-%m-%d)"
    update_field "$skill" "last_synced" "$today"
    update_field "$skill" "sha" "$sha"
    echo "[$skill] synced"
  fi
}

TARGET="${1:-}"
APPLY="${2:-}"

if [[ -z "$TARGET" || "$TARGET" == "--apply" ]]; then
  [[ "$TARGET" == "--apply" ]] && APPLY="--apply"
  for skill in $(list_upstreams); do
    sync_skill "$skill" "$APPLY"
  done
else
  sync_skill "$TARGET" "$APPLY"
fi
