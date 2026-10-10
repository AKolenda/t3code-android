# T3 Code Android builds

Personal Android builds of [T3 Code](https://github.com/pingdotgg/t3code), distributed through GitHub Releases for Obtainium.

[Add to Obtainium](https://apps.obtainium.imranr.dev/redirect?r=obtainium://add/https://github.com/AKolenda/t3code-android)

Add `https://github.com/AKolenda/t3code-android` in Obtainium. Enable automatic updates for the app and background checks. Android may require permission to install apps and approval for the first update.

The dedicated build server checks upstream `main` every 15 minutes and publishes when its commit changes. It runs as `t3builder` under `t3-android-build.timer`, with files and caches under `/opt/t3-android-builder`. A root-owned GitHub credential file is readable only by root and the build group; the script reads it for publishing. Failed builds leave the last successful commit unchanged and are retried on the next check.

The GitHub **Android APK** workflow is a manual fallback. Run it to build a specific commit or a branch from `AKolenda/t3code`. The server continues to track upstream `main`.

Server operations: `systemctl status t3-android-build.timer`, `journalctl -u t3-android-build.service`, and `systemctl start t3-android-build.service`. Disable automatic builds with `systemctl disable --now t3-android-build.timer`. To deploy automation changes, update `/opt/t3-android-builder/automation` from this repository and reload systemd if units changed.

Automated APKs support ARM64 phones. The package is `com.t3tools.t3code`, with increasing version codes based on UTC minutes since the Unix epoch. Builds retain the Expo template debug signing key used by the existing installation. These are personal builds, not official store releases; the workflow verifies the certificate before publishing.

JavaScript is bundled in the APK. Expo OTA updates are disabled. Upstream cloud sign-in and push service configuration are not included; use a direct connection to your T3 server. Each release records the exact source commit and APK checksum. App source and its license are in the linked source repository.
