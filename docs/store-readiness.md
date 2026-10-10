# Store readiness checklist

What the app declares, why, and what still needs a human before submitting. Last checked 6 Oct 2026 against the release APK and the iOS simulator build.

## Android permissions (release build, verified with `aapt2 dump permissions`)

| Permission | Why |
|---|---|
| `READ_SMS` | Reads bank transaction messages on the phone. **Restricted by Google Play** — see below. |
| `RECEIVE_SMS` | Notices a new bank SMS while the app is open (no background receiver). **Restricted by Google Play.** Could be dropped: the app also catches up on every open/resume. |
| `INTERNET` | Gmail import and the rules update talk to Google / GitHub directly. Flutter only adds this to debug builds, so it is declared. |
| `POST_NOTIFICATIONS`, `VIBRATE`, `RECEIVE_BOOT_COMPLETED` | Reminders for dues, lending and budgets; rescheduled after a reboot. |
| `USE_BIOMETRIC`, `USE_FINGERPRINT` | App lock. |

The SMS plugin also asks for location, send-SMS and phone-state permissions; they are removed in `AndroidManifest.xml` (`tools:node="remove"`), so the store listing only shows what the app uses.

Also set: `allowBackup="false"` plus data-extraction rules. The database is encrypted with a key in the Android Keystore that does not leave the phone, so a cloud-restored copy on another phone would be unreadable. The in-app encrypted export is the supported way to move phones.

Scheduled reminders need the two `flutter_local_notifications` receivers in the manifest; they were missing and are now declared.

## Google Play — needs you

1. **Permissions Declaration Form for SMS.** Play only allows `READ_SMS`/`RECEIVE_SMS` for apps whose core function needs it, and expense tracking from bank SMS is not on Google's list of automatic exceptions. Prepare: a screen recording of the permission prompt and the feature, a plain-language justification ("reads only bank transaction alerts, on-device, never uploaded"), and the privacy policy link. **Approval is not guaranteed** — have the Gmail-only mode ready as a fallback listing.
2. **Data safety form:** no data collected or shared by the developer; data is processed on-device. Gmail access is read-only (`gmail.readonly`) and stays on the phone.
3. **Google OAuth consent screen:** `gmail.readonly` is a *restricted scope*. Publishing the app to the public needs Google's OAuth verification (and possibly a security assessment). Testing mode is limited to 100 listed test users.
4. A **privacy policy URL** (required). It should mention: on-device storage, encryption, Gmail read-only, SMS read, and the anonymous rules-file download. **Gmail is also checked automatically when the app opens** (new bank emails only, at most every 3 hours, only for an account the user connected; a switch on the Gmail card turns it off) — say so in the policy and the Data safety answers.

## iOS

- `Info.plist`: `NSFaceIDUsageDescription` (Face ID), `ITSAppUsesNonExemptEncryption = false` (the app only uses standard encryption for its own on-device data — **confirm this answer with whoever owns the legal/export side**).
- `PrivacyInfo.xcprivacy`: no tracking, no collected data, and the "required reason" API categories the Flutter engine and plugins use.
- iOS cannot read SMS; the SMS card is hidden there. Gmail and manual entry work.
- `permission_handler` is built with notifications only (`PERMISSION_NOTIFICATIONS=1` in the Podfile), so no other usage strings (contacts, camera, location…) are needed.
- Share sheets pass an anchor rectangle so they don't crash on iPad.
- App Store Connect: privacy "nutrition label" = Data Not Collected.

## Not done / out of scope here

- Real-device Android validation (SMS reading, OEM battery behaviour, Keystore).
- iOS code signing and TestFlight upload.
- Play Console listing, screenshots, content rating.
