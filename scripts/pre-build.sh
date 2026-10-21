#!/usr/bin/env bash
# Runs before every build attempt. After failures, cleans progressively harder so
# leftover state from a broken build can't keep failing the next ones.
set -uo pipefail
base=${T3_BUILD_HOME:-/opt/t3-android-builder}
src="$base/source"
fails=$(cat "$base/state/fail-count" 2>/dev/null || echo 0)
(( fails == 0 )) && exit 0
step=$(( fails % 4 ))
echo "Previous $fails attempt(s) failed; cleaning before retry (step $step)"
if (( step == 3 )); then
  # Full reset: fresh clone and empty Gradle caches.
  rm -rf "$src" "$base/.gradle/caches"
elif [[ -d $src/.git ]]; then
  git -C "$src" reset --hard -q
  if (( step == 2 )); then
    # Also drops ignored files: node_modules and the prebuilt android project.
    git -C "$src" clean -ffdxq
  else
    git -C "$src" clean -ffdq
    rm -rf "$src/apps/mobile/android"
  fi
fi
exit 0
