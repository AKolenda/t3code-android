#!/usr/bin/env bash
set -euo pipefail
base=${T3_BUILD_HOME:-/opt/t3-android-builder}
source_repository=${SOURCE_REPOSITORY:-pingdotgg/t3code}
source_ref=${SOURCE_REF:-main}
release_repository=AKolenda/t3code-android
export JAVA_HOME="$base/toolchain/jdk"
export ANDROID_HOME="$base/toolchain/sdk"
export PATH="$base/toolchain/node/bin:$HOME/.local/share/vite-plus/bin:$HOME/.vite-plus/bin:$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"
export APP_VARIANT=production T3CODE_MOBILE_UPDATES_ENABLED=0
export NODE_OPTIONS=--max-old-space-size=8192
mkdir -p "$base/state" "$base/releases"
exec 9>"$base/state/build.lock"
flock -n 9 || exit 0
cd "$base"
if [[ ! -d source/.git ]]; then
  git clone --depth 1 --branch "$source_ref" "https://github.com/$source_repository.git" source
fi
git -C source fetch --depth 1 "https://github.com/$source_repository.git" "$source_ref"
sha=$(git -C source rev-parse FETCH_HEAD)
identity="$source_repository@$sha"
if [[ -f state/last-success ]] && [[ "$(cat state/last-success)" == "$identity" ]]; then
  echo "No update: $identity"
  exit 0
fi
git -C source checkout --detach "$sha"
echo "Building $identity"
cd source
NODE_ENV=development vp install --frozen-lockfile
cd apps/mobile
vp exec expo prebuild --platform android --no-install
cd "$base"
SOURCE_DIR="$base/source" python3 automation/scripts/prepare-release.py
version=$(python3 -c 'import json; print(json.load(open("release-version.json"))["version"])')
cd source/apps/mobile/android
NODE_ENV=production ./gradlew :app:assembleRelease --no-daemon --max-workers=4 -PreactNativeArchitectures=arm64-v8a -Dorg.gradle.jvmargs='-Xmx8g -XX:MaxMetaspaceSize=1g'
cd "$base"
out="$base/releases/$version"
mkdir -p "$out"
cp source/apps/mobile/android/app/build/outputs/apk/release/app-release.apk "$out/T3-Code-$version.apk"
tools=$(find "$ANDROID_HOME/build-tools" -mindepth 1 -maxdepth 1 -type d | sort -V | tail -1)
"$tools/apksigner" verify --verbose --print-certs "$out/T3-Code-$version.apk" | tee "$out/signature.txt"
grep -qi fac61745dc0903786fb9ede62a962b399f7348f0bb6f899b8332667591033b9c "$out/signature.txt"
"$tools/zipalign" -c -P 16 4 "$out/T3-Code-$version.apk"
(cd "$out" && sha256sum ./*.apk > SHA256SUMS)
cp release-version.json "$out/"
printf 'Source: %s\n\nStandalone ARM64 Android APK. Package: com.t3tools.t3code. Compatible with the existing template-signed installation. Expo OTA disabled. Direct server connections supported; upstream cloud service credentials are not included.\n' "$identity" > "$out/notes.md"
# Credentials are exposed only to the release command, not app dependency scripts.
GH_TOKEN=$(cat "$T3_GITHUB_TOKEN_FILE") gh release create "v$version" "$out/T3-Code-$version.apk" "$out/SHA256SUMS" "$out/signature.txt" "$out/release-version.json" --repo "$release_repository" --title "T3 Code v$version" --notes-file "$out/notes.md" --latest
printf '%s\n' "$identity" > state/last-success
echo "Published v$version from $identity"
