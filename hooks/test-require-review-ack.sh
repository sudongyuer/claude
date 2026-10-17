#!/usr/bin/env bash
set -u
hook="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/require-review-ack.sh"
tmp="$(mktemp -d)"; fail=0
repo="$tmp/repo"; bin="$tmp/bin"; mkdir -p "$repo" "$bin" "$tmp/elsewhere"
git -C "$repo" init -q -b feat/x && git -C "$repo" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init

cat > "$bin/gh" <<'EOF'
#!/usr/bin/env bash
case "$1 $2" in
  "pr view") [ -f "$FAKE_GH/pr" ] && cat "$FAKE_GH/pr" || exit 1 ;;
  "repo view") echo "acme widgets" ;;
  "api graphql") cat "$FAKE_GH/threads" ;;
esac
EOF
chmod +x "$bin/gh"
export FAKE_GH="$tmp" PATH="$bin:$PATH"

run() {
  python3 -c 'import json,sys;print(json.dumps({"tool_name":"Bash","cwd":sys.argv[1],"tool_input":{"command":sys.argv[2]}}))' "$1" "$2" \
    | bash "$hook" 2>/dev/null
  echo $?
}
expect() { got="$(run "$2" "$3")"; [ "$got" = "$1" ] || { echo "FAIL: want $1 got $got: $3 ($4)"; fail=1; }; }

expect 0 "$repo" "git push" "branch without a PR passes"
echo 7 > "$tmp/pr"
printf '' > "$tmp/threads"
expect 0 "$repo" "git push" "PR without unresolved threads passes"
printf -- '- a.ts:41 codex: P1 Detect active Web memberships\n' > "$tmp/threads"
expect 2 "$repo" "git push" "unresolved threads block a push"
expect 2 "$repo" "git push -q origin feat/x" "push with arguments is blocked"
expect 2 "$tmp/elsewhere" "cd $repo && git push -q origin feat/x" "cd into the repo is followed"
expect 2 "$tmp/elsewhere" "git -C $repo push" "git -C is followed"
expect 2 "$repo" "gh pr merge 7 --squash" "merge is blocked"
expect 2 "$repo" "gh pr ready" "ready is blocked"
expect 0 "$repo" "REVIEW_ACK=1 git push" "explicit acknowledgement passes"
expect 0 "$repo" "gh pr view 7" "viewing a PR passes"
expect 0 "$repo" "git status" "other git commands pass"
expect 0 "$repo" "echo 'run git push later'" "text that mentions push passes"
expect 0 "$tmp/elsewhere" "git push" "a push outside any repository passes"

rm -rf "$tmp"
[ "$fail" -eq 0 ] && echo ok; exit "$fail"
