# FPL Fees App — Completed Status

**Repo:** https://github.com/azharmarmu/fpl_fees  
**Branch:** `main`  
**Status date:** 1 Aug 2026  
**Overall:** **Firebase project `fpl-fees` wired** (`kFirebaseEnabled = true`). Finish Auth Email/Password in Console + `bash tool/create_admin.sh`. Storage optional. Distribute via App Distribution — see [`RELEASE.md`](./RELEASE.md).

Full product requirements: see [`REQUIREMENTS.md`](./REQUIREMENTS.md).  
Quick run notes: see [`README.md`](./README.md).

---

## Summary

| Area | Status |
|------|--------|
| Flutter app scaffold | Done |
| Seed squad + season weeks | Done |
| Admin fees / guests / subscription | Done |
| Eligible list + WhatsApp copy | Done |
| Finance ledger | Done |
| Scorecards (manual summary + PDF attach) | Done |
| Trades (25% commission) | Done |
| Player login (phone / username, no OTP) | Done |
| Player home + UPI | Done |
| Local persistence (SharedPreferences) | Done |
| Bulk CSV phone/username import | Done |
| Ledger export / JSON backup | Done |
| Firebase Auth / Firestore / Storage code path | Done — project `fpl-fees` live |
| Firestore rules deployed | Done |
| Auth Email/Password + admin UID | Pending one Console click + `tool/create_admin.sh` |
| Storage bucket | Pending Console (optional for PDF cloud) |
| Unit + widget tests | Done |
| Firebase App Distribution | Documented (not Play / App Store) |

---

## Done — product features

### Platform

- [x] Flutter project under `fpl_fees/`
- [x] Config constants + Firebase enable flag (`lib/config.dart`)
- [x] Models including `pdfUrl` on matches
- [x] `FplStore` local + optional Firestore sync
- [x] Session + AuthService (local password / Firebase email)
- [x] Firestore + Storage rules + `firebase.json`
- [x] `firebase_options.dart` placeholder (replace via flutterfire)
- [x] README / REQUIREMENTS / STATUS / RELEASE

### Seed data

- [x] 50 Season 2 auction squad players
- [x] Captains + lifetime members
- [x] Demo phones for captains / sample players (`kSeedPhones`)
- [x] Weeks Sun **2 Aug 2026 → 27 Dec 2026**; **8 Nov** = VPL
- [x] Sample CSV asset `assets/sample_contacts.csv`

### Admin

- [x] Login (local password; Firebase Auth when cloud on)
- [x] Fees / eligible / finance / matches / trades / contacts
- [x] PDF attach on scorecards (local file + Storage upload when cloud)
- [x] CSV import + template copy for phones/usernames
- [x] Export finance / payments / subscriptions / full JSON

### Player

- [x] Phone or username login
- [x] Eligibility + UPI
- [x] Team / scorecards (open cloud PDF) / profile

### Eligibility logic

1. Lifetime → eligible  
2. Subscription paid → eligible  
3. Weekly ₹50 for selected week → eligible  
4. Guest ₹200 that week → listed as guest eligible  
5. Else unpaid  

---

## Not done / deferred

| Item | Notes |
|------|--------|
| Run `flutterfire configure` with real project | Done (`fpl-fees`) |
| Create Auth admin + `admins/{uid}` | Enable Email/Password in Console, then `bash tool/create_admin.sh` |
| Storage Get Started | Optional — Console (may need Blaze) |
| Auto PDF scorecard parse | Out of v1 |
| In-app payment gateway | Out of scope |
| OTP login | Out of scope |
| Ground ₹1,000/week Ali split report | Ops note only |
| App Distribution to testers | See RELEASE.md |
| Play / App Store listing | Out of scope for now |

---

## How to run (current)

```bash
fvm flutter pub get && fvm flutter test && fvm flutter run
```

- **Admin password:** `fpladmin`  
- Storage: SharedPreferences; Firestore when Firebase configured  

---

## Change log (high level)

| Date | Note |
|------|------|
| 1 Aug 2026 | Initial local MVP |
| 1 Aug 2026 | REQUIREMENTS + STATUS |
| 1 Aug 2026 | Firebase project `fpl-fees`, options, Firestore rules, flag on |
