# T3 Code Android builds

Personal Android builds of [T3 Code](https://github.com/pingdotgg/t3code), distributed through GitHub Releases for Obtainium.

[Add to Obtainium](https://apps.obtainium.imranr.dev/redirect?r=obtainium://add/https://github.com/AKolenda/t3code-android)

Add `https://github.com/AKolenda/t3code-android` in Obtainium. Enable automatic updates for the app and background checks. Android may require permission to install apps and approval for the first update.

The workflow checks upstream `main` daily at 08:17 UTC and publishes when its commit changes. Changes to the workflow or scripts also trigger a build. Run **Android APK** manually to build a specific commit or a branch from `AKolenda/t3code`. Scheduled runs continue to track upstream `main`.

Automated APKs support ARM64 phones. The package is `com.t3tools.t3code`, with increasing version codes based on UTC minutes since the Unix epoch. Builds retain the Expo template debug signing key used by the existing installation. These are personal builds, not official store releases; the workflow verifies the certificate before publishing.

JavaScript is bundled in the APK. Expo OTA updates are disabled. Upstream cloud sign-in and push service configuration are not included; use a direct connection to your T3 server. Each release records the exact source commit and APK checksum. App source and its license are in the linked source repository.
