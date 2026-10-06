#!/usr/bin/env bash
# Mirror upstream skills listed in upstreams.yaml into skills/<name>/.
#
# A skill is refetched only when upstream has a new commit under its path, so
# local edits stay put until upstream moves. When it does, the whole skill is
# overwritten and the sync PR shows any local edits being reverted.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
UPSTREAMS="${REPO_DIR}/upstreams.yaml"

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

# Unauthenticated API calls share a 60/hour limit per IP; CI passes GH_TOKEN.
TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
AUTH=()
[[ -n "$TOKEN" ]] && AUTH=(-H "Authorization: Bearer ${TOKEN}")

api() {
  # ${AUTH[@]+...}: bash 3.2 (macOS) treats an empty array as unbound under set -u
  curl -fsSL ${AUTH[@]+"${AUTH[@]}"} -H "Accept: application/vnd.github+json" \
    "https://api.github.com/$1"
}

get_field() {
  python3 - "$UPSTREAMS" "$1" "$2" <<'PY'
import sys, yaml
entry = yaml.safe_load(open(sys.argv[1]))["upstreams"].get(sys.argv[2]) or {}
value = entry.get(sys.argv[3])
print("" if value is None else value)
PY
}

# set_synced <skill> <sha>: record the synced commit and today's date
set_synced() {
  python3 - "$UPSTREAMS" "$1" "$2" <<'PY'
import datetime, sys, yaml
path, skill, sha = sys.argv[1:]
data = yaml.safe_load(open(path))
data["upstreams"][skill]["last_synced"] = datetime.date.today()
data["upstreams"][skill]["sha"] = sha
with open(path, "w") as f:
    yaml.safe_dump(data, f, sort_keys=False)
PY
}

list_upstreams() {
  python3 -c 'import sys, yaml; print("\n".join(yaml.safe_load(open(sys.argv[1]))["upstreams"]))' "$UPSTREAMS"
}

# Latest commit touching <path>, so unrelated upstream commits don't trigger a sync.
fetch_path_sha() {
  local repo="$1" path="$2" ref="$3"
  api "repos/${repo}/commits?path=${path}&sha=${ref}&per_page=1" \
    | python3 -c 'import json, sys; c = json.load(sys.stdin); print(c[0]["sha"] if c else "")'
}

# fetch_tree <repo> <sha> <path> <dest>: copy <path> at <sha> into <dest>
fetch_tree() {
  local repo="$1" sha="$2" path="$3" dest="$4"
  local unpack="${dest}.unpack"
  mkdir -p "$unpack"
  curl -fsSL "https://codeload.github.com/${repo}/tar.gz/${sha}" | tar -xzf - -C "$unpack"
  # the archive's single top dir is named <repo>-<sha>
  local src
  src="$(find "$unpack" -mindepth 1 -maxdepth 1 -type d)/${path}"
  [[ -d "$src" ]] || return 1
  mv "$src" "$dest"
}

# Markdown list of upstream commits touching <path> after <old> up to <new>.
fetch_commits() {
  local repo="$1" path="$2" new="$3" old="$4"
  api "repos/${repo}/commits?path=${path}&sha=${new}&per_page=30" \
    | python3 -c '
import json, sys
repo, old = sys.argv[1:]
for c in json.load(sys.stdin):
    if c["sha"] == old:
        break
    sha, msg = c["sha"], c["commit"]["message"].split("\n")[0]
    print(f"- [{sha[:7]}](https://github.com/{repo}/commit/{sha}) {msg}")
' "$repo" "$old" || true
}

# Files git sees in a skill dir (tracked + untracked, minus ignored like .DS_Store)
local_files() {
  git -C "$REPO_DIR" ls-files --cached --others --exclude-standard -- "skills/$1" \
    | sed "s|^skills/$1/||" | sort -u
}

dir_files() { (cd "$1" && find . -type f | sed 's|^\./||' | sort); }

file_lines() { awk 'END{print NR+0}' "$1"; }

plural_lines() { [[ "$1" == 1 ]] && echo "1 line" || echo "$1 lines"; }

# echoes "<added> <removed>" for two files
diff_counts() {
  diff -u "$1" "$2" 2>/dev/null \
    | awk '/^\+\+\+/||/^---/{next} /^\+/{a++} /^-/{r++} END{print (a+0), (r+0)}'
}

sync_skill() {
  local skill="$1" apply="${2:-}"

  local repo path ref old_sha old_date
  repo="$(get_field "$skill" repo)"
  path="$(get_field "$skill" path)"
  ref="$(get_field "$skill" ref)"
  old_sha="$(get_field "$skill" sha)"
  old_date="$(get_field "$skill" last_synced)"

  # an empty path would mirror the whole upstream repo
  if [[ -z "$repo" || -z "$path" || -z "$ref" ]]; then
    echo "[$skill] needs repo, path, and ref in upstreams.yaml — skipping"
    return
  fi

  echo "[$skill] checking upstream ${repo}@${ref}..."

  local new_sha
  new_sha="$(fetch_path_sha "$repo" "$path" "$ref")"
  if [[ -z "$new_sha" ]]; then
    echo "[$skill] no commits at ${path}"
    return
  fi
  if [[ "$new_sha" == "$old_sha" ]]; then
    echo "[$skill] up to date"
    return
  fi

  local tmp
  tmp="$(mktemp -d "${TMP_ROOT}/${skill}.XXXXXX")"
  if ! fetch_tree "$repo" "$new_sha" "$path" "${tmp}/new"; then
    echo "[$skill] no files found at ${path}"
    return
  fi

  local skill_dir="${REPO_DIR}/skills/${skill}"
  local entries=""   # accumulated summary lines for this skill
  local md=""        # same, as plain-language markdown
  local rel

  # new / changed: walk upstream files
  while IFS= read -r rel; do
    local upstream_file="${tmp}/new/${rel}" local_file="${skill_dir}/${rel}"
    if [[ ! -f "$local_file" ]]; then
      echo "  [new]     ${rel}"
      entries+="$(printf '  +  %-28s +%-4s -%s' "$rel" "$(file_lines "$upstream_file")" 0)"$'\n'
      md+="- \`${rel}\` added upstream ($(plural_lines "$(file_lines "$upstream_file")"))"$'\n'
    elif ! cmp -s "$local_file" "$upstream_file"; then
      echo "  [changed] ${rel}"
      diff -u "$local_file" "$upstream_file" || true
      local added removed
      read -r added removed < <(diff_counts "$local_file" "$upstream_file")
      entries+="$(printf '  ~  %-28s +%-4s -%s' "$rel" "$added" "$removed")"$'\n'
      md+="- \`${rel}\` changed: $(plural_lines "$added") added, $(plural_lines "$removed") removed"$'\n'
    else
      continue
    fi
    if [[ "$apply" == "--apply" ]]; then
      mkdir -p "$(dirname "$local_file")"
      cp "$upstream_file" "$local_file"
    fi
  done < <(dir_files "${tmp}/new")

  # removed: local files no longer present upstream
  while IFS= read -r rel; do
    echo "  [removed] ${rel}"
    entries+="$(printf '  -  %-28s +%-4s -%s' "$rel" 0 "$(file_lines "${skill_dir}/${rel}")")"$'\n'
    md+="- \`${rel}\` removed upstream ($(plural_lines "$(file_lines "${skill_dir}/${rel}")"))"$'\n'
    if [[ "$apply" == "--apply" ]]; then
      rm -f "${skill_dir}/${rel}"
    fi
  done < <(comm -23 <(local_files "$skill") <(dir_files "${tmp}/new"))

  [[ -n "$md" ]] || md="- no file changes"$'\n'

  SYNC_BODY+="$(printf '%s  [%s -> %s]' "$skill" "${old_sha:0:7}" "${new_sha:0:7}")"$'\n'
  SYNC_BODY+="$entries"$'\n'

  SYNC_MD+="### ${skill}"$'\n\n'
  SYNC_MD+="Source: [${repo}/${path}](https://github.com/${repo}/tree/${new_sha}/${path})"$'\n\n'
  SYNC_MD+="${md}"$'\n'
  if [[ -n "$old_sha" ]]; then
    local commits
    commits="$(fetch_commits "$repo" "$path" "$new_sha" "$old_sha")"
    [[ -n "$commits" ]] && SYNC_MD+="Upstream commits since ${old_date:-${old_sha:0:7}}:"$'\n\n'"${commits}"$'\n\n'
  fi

  if [[ "$apply" == "--apply" ]]; then
    set_synced "$skill" "$new_sha"
    echo "[$skill] synced to ${new_sha:0:7}"
  fi
}

write_summary() {
  [[ -n "$SYNC_BODY" ]] || return 0
  printf '\n%s' "$SYNC_BODY"            # marker tree to stdout (every run)
  [[ -n "$SUMMARY_FILE" ]] || return 0
  {                                     # markdown copy for the CI PR body
    printf '## Upstream sync, %s\n\n' "$(date +%Y-%m-%d)"
    printf '%s' "$SYNC_MD"
    printf 'Sync overwrites the whole skill, so local edits show up here as reverted.\n'
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
