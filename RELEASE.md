# Release / distribute — FPL Fees

**Native installs:** Firebase App Distribution (not Play Store / App Store).  
**Web (phone / tablet / laptop):** Firebase Hosting — same Firestore data as mobile.

Firebase project: **`fpl-fees`**  
Console: https://console.firebase.google.com/project/fpl-fees/overview

Use FVM for all Flutter commands:

```bash
fvm flutter …
```

Pinned SDK: see `.fvmrc` (currently **3.44.2**).

---

## Prerequisites

- [FVM](https://fvm.app) + pinned Flutter
- Firebase CLI (`firebase-tools`) — logged in as project owner
- Testers’ emails / App Distribution group (native only)

---

## Local / debug

```bash
fvm flutter pub get
fvm flutter test
fvm flutter run
fvm flutter run -d chrome   # web
```

Cursor / VS Code: run **fpl_fees** from Run and Debug (FVM SDK via `.vscode/settings.json`).

---

## Web → Firebase Hosting

Public URLs (after deploy):

- https://fpl-fees.web.app  
- https://fpl-fees.firebaseapp.com  

```bash
bash tool/deploy_web.sh
# or re-upload existing build/web:
bash tool/deploy_web.sh --skip-build
```

Builds with `--pwa-strategy=none` (no service worker) so Chrome does not keep serving an old cached app.  
If a normal tab still looks stale once: hard refresh (`Cmd+Shift+R`) or clear site data for `fpl-fees.web.app`.

Same login as mobile: player phone/username, admin Firebase email/password (or local `fpladmin` fallback).  
Auth authorized domains should include `fpl-fees.web.app` and `fpl-fees.firebaseapp.com` (Console usually adds these automatically).

---

## Firebase status (already done in repo)

| Step | Status |
|------|--------|
| Project `fpl-fees` | Done |
| Android + iOS + Web apps registered | Done |
| `lib/firebase_options.dart` | Done (Android / iOS / Web) |
| `google-services.json` / `GoogleService-Info.plist` | Done |
| `kFirebaseEnabled` + `kAllowFirebaseOnWeb` | Done (`true`) |
| Firestore `(default)` in `asia-south1` | Done |
| Firestore rules deployed | Done |
| Firebase Hosting | `bash tool/deploy_web.sh` |
| Auth Email/Password | **You must enable in Console** (one click) |
| Admin Auth user + `admins/{uid}` | Run `tool/create_admin.sh` after Auth |
| Storage bucket | **Enable in Console** (may require Blaze billing) |

### Finish Auth (required for admin cloud writes)

1. Open https://console.firebase.google.com/project/fpl-fees/authentication/providers  
2. Click **Get Started** → enable **Email/Password** → Save.  
3. Create admin user + allow-list doc:

```bash
bash tool/create_admin.sh
# defaults: marmuazhardev@gmail.com / fpladmin
# override: ADMIN_EMAIL=you@x.com ADMIN_PASSWORD='…' bash tool/create_admin.sh
```

4. Run the app. Admin tab can use Firebase email/password; local `fpladmin` remains emergency fallback. Dashboard shows **Cloud sync ON** when online.

### Finish Storage (optional — PDF cloud upload)

1. Open https://console.firebase.google.com/project/fpl-fees/storage  
2. Click **Get Started** (Blaze may be required on new projects).  
3. Then:

```bash
firebase deploy --only storage --project fpl-fees
```

Until Storage is on, scorecard PDFs still save **locally** on device.

---

## Android + iOS → App Distribution

Preferred: one script builds and uploads both platforms to a tester group.

```bash
# Both platforms → group "testers" (default notes = today's date)
bash tool/distribute.sh

# Custom group + release notes
bash tool/distribute.sh --group testers --notes "Fees config + weekly toggle fix"

# Notes from a file
bash tool/distribute.sh -g testers --notes-file notes.txt

# One platform only
bash tool/distribute.sh --platform android
bash tool/distribute.sh --platform ios

# Re-upload existing artifacts (skip flutter build)
bash tool/distribute.sh --skip-build --group testers --notes "hotfix"

# iOS signing export method (default ad-hoc). Fallback if ad-hoc fails:
bash tool/distribute.sh --platform ios --ios-export development
```

Artifacts:
- Android: `build/app/outputs/flutter-apk/app-release.apk` (`com.fpl.fpl_fees`)
- iOS: `build/ios/ipa/*.ipa` (`com.fpl.fplFees`)

App IDs (already in the script):
- Android `1:283215487299:android:c17cf44bf9cd9e2c8b4ff6`
- iOS `1:283215487299:ios:c6c8722ad48fb7df8b4ff6`

Or drag-and-drop binaries in Console → App Distribution.

---

## Pre-distribute smoke test

- [ ] Admin login (Firebase email or local fallback)  
- [ ] Mark weekly / subscription / guest  
- [ ] Eligible WhatsApp copy  
- [ ] Second device sees same data (Firestore)  
- [ ] PDF attach (local always; cloud after Storage)  
- [ ] Fresh install from App Distribution link  

---

## Backup

More → **Export ledger / backup** → Full season JSON.

---

## Out of scope (for now)

- Google Play Store / Apple App Store listings
