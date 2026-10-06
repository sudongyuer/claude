#!/usr/bin/env bash
set -u
hook="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/block-disabled-signing.sh"
fail=0

expect() {
  local want="$1" command="$2" got
  printf '{"tool_name":"Bash","tool_input":{"command":%s}}' "$command" | bash "$hook" 2>/dev/null
  got=$?
  if [ "$got" -ne "$want" ]; then
    echo "FAIL: want exit $want, got $got for $command"
    fail=1
  fi
}

expect 2 '"xcodebuild -scheme App CODE_SIGNING_ALLOWED=NO build"'
expect 2 '"xcodebuild CODE_SIGNING_ALLOWED = NO"'
expect 2 '"xcodebuild CODE_SIGNING_ALLOWED=\"NO\""'
expect 2 '"xcodebuild CODE_SIGNING_ALLOWED='"'"'NO'"'"'"'
expect 0 '"xcodebuild -scheme App build"'
expect 0 '"xcodebuild CODE_SIGNING_ALLOWED=YES"'

[ "$fail" -eq 0 ] && echo "ok"
exit "$fail"
