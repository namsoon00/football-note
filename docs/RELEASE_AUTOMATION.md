# Mobile Release Automation

This project supports automated iOS/Android deployment through GitHub Actions and Fastlane.

## Workflow

- File: `.github/workflows/mobile-release.yml`
- Trigger:
  - Manual: `workflow_dispatch`
  - Tag release: `v*` (example: `v1.2.0`)
- Behavior:
  - `beta`: iOS TestFlight + Google Play internal track
  - `production`: App Store Connect + Google Play production track

## Required GitHub Secrets

### iOS

- `ASC_KEY_ID`: App Store Connect API key id
- `ASC_ISSUER_ID`: App Store Connect issuer id
- `ASC_KEY_CONTENT`: Base64 encoded `.p8` key content
- `IOS_DISTRIBUTION_CERT_B64`: Base64 encoded distribution certificate (`.p12`)
- `IOS_DISTRIBUTION_CERT_PASSWORD`: Password for `.p12`
- `IOS_PROVISIONING_PROFILE_B64`: Base64 encoded App Store provisioning profile (`.mobileprovision`)
- `KEYCHAIN_PASSWORD`: Temporary CI keychain password

### Android

- `ANDROID_UPLOAD_KEYSTORE_B64`: Base64 encoded upload keystore (`.jks`)
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `PLAY_JSON_KEY`: Google Play service-account JSON content

Workflow runs `./scripts/check_release_secrets.sh ios|android` first and fails fast with an explicit missing-key list.

## One-time Platform Setup

### iOS

1. Create App ID `com.namsoon.footballnote` in Apple Developer.
2. Create App Store Connect app for the same bundle id.
3. Create and download:
   - iOS Distribution certificate (`.p12`)
   - App Store provisioning profile
4. Register App Store Connect API key.

### Android

1. Create app in Google Play Console (`com.namsoon.footballnote`).
2. Enable Play App Signing.
3. Create upload keystore and keep it safely.
4. Create service account and grant Play Console release permissions.

## Local Commands

- Beta build/deploy (through CI): run `Mobile Release` workflow with `channel=beta`.
- Production release: push a tag:

```bash
git tag v1.0.1
git push origin v1.0.1
```

## Notes

- `android/key.properties` and keystore files are generated in CI from secrets.
- iOS/Android build signing cannot complete without platform credentials.
- If local Android build fails with SSL trust errors, run release builds in GitHub Actions runner.
