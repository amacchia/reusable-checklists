---
name: publish-play-store
description: Prepare and build a Google Play Store release for this Flutter app. Use when the user wants to publish, release, ship, or upload an update to the Play Store, build a signed release/AAB, or bump the release version.
---

# Publish Play Store Update

## What this skill does

Everything automatable on the local machine for a Play Store release:
verify the repo is release-ready, bump the version, run quality gates,
build a signed AAB, and hand the user a checklist for the Play Console
steps (which must be done manually in the web console).

## Workflow

### 1. Verify clean state

```bash
git status --porcelain   # must be clean; ask user how to proceed if not
```

Also check `git log --oneline -5` to understand what's being released.

### 2. Bump the version

Edit `pubspec.yaml` line 4 (currently `version: 1.0.0+2`). Format is
`versionName+versionCode`:

- Increment `versionName` semantically (patch for fixes, minor for features).
- **Always increment the `+versionCode` integer** — Play Console rejects
  uploads with a versionCode equal to or lower than the current production
  release.

Confirm the new version with the user before building.

### 3. Run quality gates (in order)

```bash
dart run build_runner build --delete-conflicting-outputs  # only if Hive models changed
flutter test --coverage                                   # CI requires >=95% line coverage
dart analyze --fatal-infos
```

If tests or analysis fail, stop and fix before building.

### 4. Build the release bundle

```bash
flutter build appbundle --release
```

Output lands at `build/app/outputs/bundle/release/app-release.aab`.

### 5. Sanity-check the artifact

```bash
ls -lh build/app/outputs/bundle/release/app-release.aab
unzip -p build/app/outputs/bundle/release/app-release.aab \
  base/manifest/AndroidManifest.xml > /dev/null && echo "bundle OK"
```

Optionally verify the versionCode baked into the build:

```bash
$ANDROID_HOME/build-tools/<ver>/aapt dump badging \
  build/app/outputs/bundle/release/app-release.aab 2>/dev/null | head -2
```

(If `aapt` isn't available, skip this — the build step already validates
the bundle internally.)

### 6. What must be done manually (remind the user)

- Open <https://play.google.com/console> → the app → **Production** →
  **Create new release**.
- Upload `build/app/outputs/bundle/release/app-release.aab`.
- Add release notes for the new `versionName`.
- Choose full or staged rollout, then submit for review.
- Review typically takes hours to a few days; rollout goes live
  automatically after approval.

### Notes about this project's signing

- Signing config is read from `android/key.properties` in
  `android/app/build.gradle.kts` (already present). If that file is
  ever missing, the release build silently falls back to the **debug**
  keystore — Play Console would then reject the upload. Never commit
  `key.properties` or the keystore; if a build unexpectedly falls back,
  stop and ask the user.
- CI (`dart analyze --fatal-infos`, 95% coverage) runs on every push —
  gates in step 3 mirror CI so a passing local build means a green CI.
- After a successful upload, the user may want to tag the release
  (e.g. `v1.0.1`) — ask before creating any git tag or commit.