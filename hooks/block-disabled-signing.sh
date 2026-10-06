#!/usr/bin/env bash
input="$(cat)"
if printf '%s' "$input" | grep -Eq 'CODE_SIGNING_ALLOWED[[:space:]]*=[[:space:]]*(\\?["'"'"'])?NO'; then
  echo "Blocked: CODE_SIGNING_ALLOWED=NO strips Keychain entitlements, so the app launches and then cannot sync. Fix signing instead of disabling it." >&2
  exit 2
fi
exit 0
