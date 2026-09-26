#!/usr/bin/env bash
set -euo pipefail

MANIFEST="$(dirname "$0")/MANIFEST.yaml"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# The marker-tree summary always prints to stdout. When SYNC_SUMMARY is set, a
# plain-language markdown version is also written there (used by CI for the PR
# body). SYNC_BODY and SYNC_MD are the internal accumulators.
SUMMARY_FILE="${SYNC_SUMMARY:-}"
SYNC_BODY=""
SYNC_MD=""

# One root for all per-skill temp dirs; a trap set inside sync_skill would be
# replaced on each loop iteration and leak the earlier dirs.
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

parse_field() {
  local skill="$1" field="$2"
  awk "/^  ${skill}:/{f=1} f && /^    ${field}:/{sub(/^    ${field}: /, \"\"); print; exit}" "$MANIFEST"
}

update_field() {
  local skill="$1" field="$2" value="$3"
  local tmp
  tmp="$(mktemp)"
  # avoid `sed -i` — its syntax differs between BSD (macOS) and GNU (Linux/CI)
  sed "/^  ${skill}:/,/^  [^ ]/ s|^    ${field}: .*|    ${field}: ${value}|" "$MANIFEST" > "$tmp"
  mv "$tmp" "$MANIFEST"
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

file_lines() { awk 'END{print NR+0}' "$1"; }

plural_lines() { [[ "$1" == 1 ]] && echo "1 line" || echo "$1 lines"; }

# Markdown list of upstream commits touching <path> since <date>, so the PR
# links to what actually changed.
fetch_commits() {
  local repo="$1" path="$2" ref="$3" since="$4"
  curl -fsSL "https://api.github.com/repos/${repo}/commits?path=${path}&sha=${ref}&since=${since}T00:00:00Z&per_page=20" \
    | python3 -c '
import json, sys
repo = sys.argv[1]
for c in json.load(sys.stdin):
    msg = c["commit"]["message"].split("\n")[0]
    sha = c["sha"]
    print(f"- [{sha[:7]}](https://github.com/{repo}/commit/{sha}) {msg}")
' "$repo" || true
}

# echoes "<added> <removed>" for two files
diff_counts() {
  diff -u "$1" "$2" 2>/dev/null \
    | awk '/^\+\+\+/||/^---/{next} /^\+/{a++} /^-/{r++} END{print (a+0), (r+0)}'
}

sync_skill() {
  local skill="$1" apply="${2:-}"

  local repo path ref old_sha old_date
  repo="$(parse_field "$skill" "repo")"
  path="$(parse_field "$skill" "path")"
  ref="$(parse_field "$skill" "ref")"
  old_sha="$(parse_field "$skill" "sha")"
  old_date="$(parse_field "$skill" "last_synced")"

  if [[ -z "$repo" || "$repo" == "~" ]]; then
    echo "[$skill] no repo in MANIFEST — skipping"
    return
  fi

  local tmp
  tmp="$(mktemp -d "${TMP_ROOT}/${skill}.XXXXXX")"

  echo "[$skill] fetching from upstream ${repo}@${ref}..."

  local files
  files="$(fetch_file_list "$repo" "$path" "$ref")"

  if [[ -z "$files" ]]; then
    echo "[$skill] no files found at ${path}"
    return
  fi

  local has_diff=false
  local entries=""   # accumulated summary lines for this skill
  local md=""        # same, as plain-language markdown

  # new / changed: walk upstream files
  while IFS= read -r rel; do
    local raw_url="https://raw.githubusercontent.com/${repo}/${ref}/${path}/${rel}"
    local local_file="${REPO_DIR}/${skill}/${rel}"
    local tmp_file="${tmp}/${rel}"

    mkdir -p "$(dirname "$tmp_file")"
    curl -fsSL "$raw_url" -o "$tmp_file"

    if [[ ! -f "$local_file" ]]; then
      echo "  [new]     ${rel}"
      entries+="$(printf '  +  %-28s +%-4s -%s' "$rel" "$(file_lines "$tmp_file")" 0)"$'\n'
      md+="- \`${rel}\` added upstream ($(plural_lines "$(file_lines "$tmp_file")"))"$'\n'
      has_diff=true
      if [[ "$apply" == "--apply" ]]; then
        mkdir -p "$(dirname "$local_file")"
        cp "$tmp_file" "$local_file"
      fi
    elif ! diff -q "$local_file" "$tmp_file" > /dev/null 2>&1; then
      echo "  [changed] ${rel}"
      diff -u "$local_file" "$tmp_file" || true
      read -r added removed < <(diff_counts "$local_file" "$tmp_file")
      entries+="$(printf '  ~  %-28s +%-4s -%s' "$rel" "$added" "$removed")"$'\n'
      md+="- \`${rel}\` changed: $(plural_lines "$added") added, $(plural_lines "$removed") removed"$'\n'
      has_diff=true
      if [[ "$apply" == "--apply" ]]; then
        cp "$tmp_file" "$local_file"
      fi
    fi
  done <<< "$files"

  # removed: local .md files no longer present upstream
  if [[ -d "${REPO_DIR}/${skill}" ]]; then
    while IFS= read -r local_file; do
      local rel="${local_file#"${REPO_DIR}/${skill}/"}"
      if ! grep -Fxq "$rel" <<< "$files"; then
        echo "  [removed] ${rel}"
        entries+="$(printf '  -  %-28s +%-4s -%s' "$rel" 0 "$(file_lines "$local_file")")"$'\n'
        md+="- \`${rel}\` removed upstream ($(plural_lines "$(file_lines "$local_file")"))"$'\n'
        has_diff=true
        if [[ "$apply" == "--apply" ]]; then
          rm -f "$local_file"
        fi
      fi
    done < <(find "${REPO_DIR}/${skill}" -type f -name '*.md')
  fi

  if ! $has_diff; then
    echo "[$skill] up to date"
    return
  fi

  local new_sha
  new_sha="$(fetch_tree_sha "$repo" "$ref")"

  SYNC_BODY+="$(printf '%s  [%s -> %s]' "$skill" "${old_sha:0:7}" "${new_sha:0:7}")"$'\n'
  SYNC_BODY+="$entries"$'\n'

  SYNC_MD+="### ${skill}"$'\n\n'
  SYNC_MD+="Source: [${repo}/${path}](https://github.com/${repo}/tree/${ref}/${path})"$'\n\n'
  SYNC_MD+="${md}"$'\n'
  if [[ -n "$old_date" && "$old_date" != "~" ]]; then
    local commits
    commits="$(fetch_commits "$repo" "$path" "$ref" "$old_date")"
    [[ -n "$commits" ]] && SYNC_MD+="Upstream commits since ${old_date}:"$'\n\n'"${commits}"$'\n\n'
  fi

  if [[ "$apply" == "--apply" ]]; then
    update_field "$skill" "last_synced" "$(date +%Y-%m-%d)"
    update_field "$skill" "sha" "$new_sha"
    echo "[$skill] synced"
  fi
}

write_summary() {
  [[ -n "$SYNC_BODY" ]] || return 0
  printf '\n%s' "$SYNC_BODY"            # marker tree to stdout (every run)
  [[ -n "$SUMMARY_FILE" ]] || return 0
  {                                     # markdown copy for the CI PR body
    printf '## Upstream sync, %s\n\n' "$(date +%Y-%m-%d)"
    printf '%s' "$SYNC_MD"
    printf 'Review the diff, then merge to take the upstream changes or close to keep the current version.\n'
  } > "$SUMMARY_FILE"
}

# Default mode applies; --diff makes it a read-only preview.
SKILL=""
APPLY="--apply"

for arg in "$@"; do
  case "$arg" in
    --diff) APPLY="" ;;
    -*) echo "unknown option: $arg" >&2; exit 2 ;;
    *) SKILL="$arg" ;;
  esac
done

if [[ -n "$SKILL" ]]; then
  sync_skill "$SKILL" "$APPLY"
else
  for skill in $(list_upstreams); do
    sync_skill "$skill" "$APPLY"
  done
fi

write_summary
