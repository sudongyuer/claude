#!/usr/bin/env bash
set -u
hook="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/require-retro.sh"
tmp="$(mktemp -d)"; fail=0
git -C "$tmp" init -q -b feat/x && git -C "$tmp" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
run() { printf '{"tool_name":"Bash","cwd":"%s","tool_input":{"command":"%s"}}' "$tmp" "$1" | bash "$hook" 2>/dev/null; echo $?; }
expect() { got="$(run "$2")"; [ "$got" = "$1" ] || { echo "FAIL: want $1 got $got: $2 ($3)"; fail=1; }; }
expect 0 "gh pr create --fill" "repo without docs/retros is not gated"
mkdir -p "$tmp/docs/retros"
expect 2 "gh pr create --fill" "opted-in repo without a retro is blocked"
expect 0 "RETRO_SKIP=1 gh pr create --fill" "explicit waiver passes"
expect 0 "gh pr view 3" "other gh commands pass"
expect 0 "cat > notes.md <<EOF\\nA hook blocks gh pr create until a retro exists\\nEOF" "text that only mentions the command passes"
expect 2 "git push && gh pr create --fill" "chained create is blocked"
expect 2 "A=1 gh pr create --fill" "env-prefixed create is blocked"
printf -- '---\nbranch: feat/other\n---\n' > "$tmp/docs/retros/a.md"
expect 2 "gh pr create --fill" "retro for another branch does not count"
printf -- '---\nbranch: feat/x\n---\n' > "$tmp/docs/retros/b.md"
expect 0 "gh pr create --fill" "retro for this branch passes"
rm -rf "$tmp"
[ "$fail" -eq 0 ] && echo ok; exit "$fail"
