#!/usr/bin/env bash
# Runs as root after every build attempt (ExecStopPost). Counts consecutive
# failures and keeps one GitHub issue open while the builder is failing.
set -uo pipefail
base=${T3_BUILD_HOME:-/opt/t3-android-builder}
repo=AKolenda/t3code-android
title="Automated Android build is failing"
count="$base/state/fail-count"
GH_TOKEN=$(cat /etc/t3-android-builder/github-token)
export GH_TOKEN
issue=$(gh issue list --repo "$repo" --state open --limit 100 --json number,title \
  --jq "map(select(.title == \"$title\"))[0].number // empty")

if [[ ${SERVICE_RESULT:-} == success ]]; then
  echo 0 > "$count"
  chown t3builder:t3builder "$count"
  # Published APKs live on GitHub; keep only the newest few locally.
  ls -1dt "$base"/releases/*/ 2>/dev/null | tail -n +6 | xargs -r rm -rf
  if [[ -n $issue ]]; then
    gh issue close "$issue" --repo "$repo" --comment "Builds are working again: $(cat "$base/state/last-success")"
  fi
  exit 0
fi

fails=$(( $(cat "$count" 2>/dev/null || echo 0) + 1 ))
echo "$fails" > "$count"
chown t3builder:t3builder "$count"
# One failure is often transient; report from the second, then every 2 hours.
(( fails < 2 )) && exit 0
[[ -n $issue ]] && (( fails % 8 != 0 )) && exit 0
log=$(journalctl _SYSTEMD_INVOCATION_ID="${INVOCATION_ID:-}" --no-pager -o cat -n 80 | cut -c1-300)
body=$(printf 'Consecutive failed attempts: %s\nLast result: %s (%s %s) on %s\n\nThe builder retries the latest upstream `main` every 15 minutes and cleans its checkout harder after each failure. This issue closes itself on the next successful build.\n\n<details><summary>Last attempt log</summary>\n\n```\n%s\n```\n</details>\n' \
  "$fails" "${SERVICE_RESULT:-unknown}" "${EXIT_CODE:-}" "${EXIT_STATUS:-}" "$(hostname)" "$log")
if [[ -n $issue ]]; then
  gh issue comment "$issue" --repo "$repo" --body "$body"
else
  gh issue create --repo "$repo" --title "$title" --body "$body"
fi
exit 0
