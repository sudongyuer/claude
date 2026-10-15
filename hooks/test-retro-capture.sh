#!/usr/bin/env bash
set -u
hook="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/retro-capture.sh"
tmp="$(mktemp -d)"; fail=0
git -C "$tmp" init -q
run() { printf '%s' "$1" | bash "$hook"; }
expect() { out="$(run "$2")"; if [ "$1" = "say" ] && [ -z "$out" ]; then echo "FAIL (silent): $3"; fail=1; fi; if [ "$1" = "quiet" ] && [ -n "$out" ]; then echo "FAIL (spoke): $3"; fail=1; fi; }
p() { printf '{"hook_event_name":"UserPromptSubmit","cwd":"%s","prompt":"%s"}' "$tmp" "$1"; }
t() { printf '{"hook_event_name":"%s","cwd":"%s","tool_name":"Bash","tool_input":{"command":"%s"},"tool_response":{"stdout":"%s","stderr":""}}' "$1" "$tmp" "$2" "$3"; }
expect quiet "$(p '为什么不行')" "repo without docs/retros stays silent"
mkdir -p "$tmp/docs/retros"
expect say "$(p '如果我不提醒你，你会记么')" "correction cue"
expect say "$(p 'why did this happen')" "english cue"
expect quiet "$(p '开始')" "plain go-ahead"
expect quiet "$(p '<pasted_content id=\"1\">为什么</pasted_content id=\"1\">好的')" "pasted text ignored"
expect say "$(t PostToolUse 'bun run verify:ui' '  12.0  fail   zh-Hans dark  home')" "verify failure"
expect say "$(t PostToolUse 'bun test' 'TimeoutExpired')" "timeout"
expect quiet "$(t PostToolUse 'bun run verify:ui' '  12.0  pass   zh-Hans dark  home')" "verify pass"
expect quiet "$(t PostToolUse 'ls' 'fail')" "non-check command"
rm -rf "$tmp"
[ "$fail" -eq 0 ] && echo ok; exit "$fail"
