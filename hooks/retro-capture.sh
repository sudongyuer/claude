#!/usr/bin/env bash
input="$(cat)"
python3 - "$input" <<'PY'
import json, os, re, subprocess, sys
d = json.loads(sys.argv[1] or '{}')
cwd = d.get('cwd') or '.'
try:
    root = subprocess.run(['git', '-C', cwd, 'rev-parse', '--show-toplevel'], capture_output=True, text=True, check=True).stdout.strip()
except Exception:
    sys.exit(0)
if not os.path.isdir(os.path.join(root, 'docs', 'retros')):
    sys.exit(0)
event = d.get('hook_event_name', '')
if event == 'UserPromptSubmit':
    prompt = re.sub(r'<pasted_content[^>]*>.*?</pasted_content[^>]*>', '', d.get('prompt', ''), flags=re.S)
    if '<task-notification>' in prompt or 'SYSTEM NOTIFICATION' in prompt:
        sys.exit(0)
    cues = r'不是|不对|错了|又|为什么|怎么没|有没有|是不是|你应该|我不提醒|浪费|误判|没生效|没用|忘了|\bwhy\b|\bwrong\b|\bagain\b|should have|did you'
    if re.search(cues, prompt, re.I):
        print('compound-loop: this message may correct you or point at something you should have caught. '
              'If so, add a candidate to the running retro in docs/retros/ now (what happened, cost, root-cause class, a tag), '
              'then answer with implications and a recommendation.')
    sys.exit(0)
if event in ('PostToolUse', 'PostToolUseFailure') and d.get('tool_name') == 'Bash':
    cmd = (d.get('tool_input') or {}).get('command', '')
    if not re.search(r'verify:ui|verify:build|bun test|tsc|lint|pgtap|test:stack|xcodebuild|run\.py', cmd):
        sys.exit(0)
    r = d.get('tool_response') or {}
    out = (r.get('stdout', '') + r.get('stderr', '')) if isinstance(r, dict) else str(r)
    out += d.get('error', '') or ''
    if re.search(r'(^|\s)(fail|FAIL)(\s|$)|timed out|TimeoutExpired|Exit code [1-9]|\berror\b', out):
        print(json.dumps({'hookSpecificOutput': {'hookEventName': event,
            'additionalContext': 'compound-loop: a check failed or timed out. Record it in the running retro with a tag '
            '(for example screenshot-timeout) and look for earlier entries with the same tag. Blaming the environment '
            'needs evidence: load average, render-server CPU, a rerun. Do not report a long run as healthy without reading its log.'}}))
PY
exit 0
