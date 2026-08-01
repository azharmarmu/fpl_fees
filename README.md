# FPL Fees (Flutter)

Season 2 app for Farm Premier League: ground fees, CricHeroes eligibility, scorecards, trades, organizer finance.

- Full requirements: [`REQUIREMENTS.md`](./REQUIREMENTS.md)
- Completed status: [`STATUS.md`](./STATUS.md)
- App Distribution / release notes: [`RELEASE.md`](./RELEASE.md)

## Run (local mode — works today)

```bash
cd fpl_fees
fvm flutter pub get
fvm flutter run
```

Uses FVM-pinned Flutter (see `.fvmrc`). In Cursor/VS Code, use the **fpl_fees** launch config.

- **Admin password:** `fpladmin`
- Data is stored on device (`SharedPreferences`); syncs to Firestore when Firebase is enabled.
- Demo player phones (replace later): captains `9000000001`–`9000000003` — see `lib/data/seed.dart`.

## What works now

### Admin
- Dashboard (week picker, paid/unpaid, finance total, cloud sync badge)
- Fees: mark ₹50 / ₹750 subscription / guest ₹200
- Lifetime members pre-seeded — no fee
- Eligible list + copy for WhatsApp
- Finance: season total by weekly / subscription / guest / trade commission
- Scorecards: add match summary + **attach CricHeroes PDF** (local + Storage when cloud on)
- Trades: enable trade window → record sale (25% commission)
- Contacts: edit phones/usernames, **CSV import** (paste or file), copy template
- Export / backup: finance CSV + full JSON

### Player
- Login with **phone** OR **username** (no OTP)
- Home: eligibility + UPI `marmuazhar@ybl`
- My team, scorecards (open PDF URL when available), profile

## Seed / bulk phones

1. Login as admin → More → Edit player phones / usernames
2. Copy CSV template (toolbar) or use [`assets/sample_contacts.csv`](./assets/sample_contacts.csv)
3. Fill real phones → Import CSV file / Paste CSV

Default username = player display name (so “Anas” works immediately).

## Firebase (multi-device sync)

Project: **`fpl-fees`** — already wired (`kFirebaseEnabled = true`).

Finish setup (one-time Console steps):

1. [Enable Email/Password Auth](https://console.firebase.google.com/project/fpl-fees/authentication/providers) → Get Started → Email/Password  
2. `bash tool/create_admin.sh` (creates `marmuazhardev@gmail.com` / `fpladmin` + `admins/{uid}`)  
3. Optional: [Enable Storage](https://console.firebase.google.com/project/fpl-fees/storage) for cloud PDF upload  
4. Ship APK via App Distribution — see [`RELEASE.md`](./RELEASE.md)

Local password `fpladmin` remains an emergency fallback if Auth is not ready.

## Fees reminder

| Type | Amount |
|------|--------|
| Weekly | ₹50 |
| Season subscription | ₹750 |
| Guest (day only) | ₹200 |
| Trade commission | 25% of sale |

## Tests

```bash
fvm flutter test
```
