#!/usr/bin/env bash
input="$(cat)"
field() { printf '%s' "$input" | python3 -c "import json,sys;d=json.load(sys.stdin);print($1)" 2>/dev/null; }
command="$(field 'd.get("tool_input",{}).get("command","")')"
start='(^|[;&|(][[:space:]]*)([A-Z_]+=[^[:space:]]+[[:space:]]+)*'
printf '%s\n' "$command" | grep -Eq "${start}(git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+push|gh[[:space:]]+pr[[:space:]]+(merge|ready))" || exit 0
printf '%s\n' "$command" | grep -Eq '(^|[;&|(][[:space:]]*)REVIEW_ACK=1[[:space:]]' && exit 0

# Agents run `cd <repo> && git push` from another directory, so the session cwd is not the repo.
dir="$(printf '%s\n' "$command" | grep -Eo '(cd|git[[:space:]]+-C)[[:space:]]+[^[:space:];&|]+' | tail -1 | awk '{print $NF}')"
dir="${dir//\"/}"; dir="${dir//\'/}"
[ -n "$dir" ] || dir="$(field 'd.get("cwd","")')"
root="$(git -C "${dir:-.}" rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$root" || exit 0

pr="$(gh pr view --json number -q .number 2>/dev/null)" || exit 0
[ -n "$pr" ] || exit 0
repo="$(gh repo view --json owner,name -q '.owner.login + " " + .name' 2>/dev/null)" || exit 0
read -r owner name <<<"$repo"
threads="$(gh api graphql -F owner="$owner" -F name="$name" -F number="$pr" -f query='
  query($owner: String!, $name: String!, $number: Int!) {
    repository(owner: $owner, name: $name) {
      pullRequest(number: $number) {
        reviewThreads(first: 100) {
          nodes { isResolved path line originalLine comments(first: 1) { nodes { author { login } body } } }
        }
      }
    }
  }' --jq '.data.repository.pullRequest.reviewThreads.nodes[]
    | select(.isResolved | not)
    | "- \(.path):\(.line // .originalLine // "?") \(.comments.nodes[0].author.login): \(.comments.nodes[0].body | gsub("!\\[(?<a>[^]]*)\\]\\([^)]*\\)"; "\(.a)") | gsub("<[^>]+>|\\*\\*"; "") | split("\n") | map(select(test("[A-Za-z]"))) | .[0] // "" | ltrimstr(" ") | .[0:160])"' 2>/dev/null)" || exit 0
[ -n "$threads" ] || exit 0

{
  echo "Blocked: PR #$pr has unresolved review threads. Read each one and fix or answer it first:"
  printf '%s\n' "$threads"
  echo "Then resolve the threads, or prefix the command with REVIEW_ACK=1 once every thread is handled."
} >&2
exit 2
