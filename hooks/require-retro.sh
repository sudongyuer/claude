#!/usr/bin/env bash
input="$(cat)"
command="$(printf '%s' "$input" | python3 -c 'import json,sys;print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null)"
printf '%s\n' "$command" | grep -Eq '(^|[;&|(][[:space:]]*)([A-Z_]+=[^[:space:]]+[[:space:]]+)*gh[[:space:]]+pr[[:space:]]+create' || exit 0
printf '%s\n' "$command" | grep -Eq '(^|[;&|(][[:space:]]*)RETRO_SKIP=1[[:space:]]' && exit 0
cwd="$(printf '%s' "$input" | python3 -c 'import json,sys;print(json.load(sys.stdin).get("cwd",""))' 2>/dev/null)"
root="$(git -C "${cwd:-.}" rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -d "$root/docs/retros" ] || exit 0
branch="$(git -C "$root" rev-parse --abbrev-ref HEAD)"
if grep -lqs "^branch: $branch\$" "$root"/docs/retros/*.md; then exit 0; fi
echo "Blocked: no retro for branch '$branch'. Run the compound-loop skill (docs/retros/<date>-<topic>.md with 'branch: $branch'), or prefix the command with RETRO_SKIP=1 if the user waived it." >&2
exit 2
