# FPL Fees (Flutter)

Season 2 app for Farm Premier League: ground fees, CricHeroes eligibility, scorecards, trades, organizer finance.

- Full requirements: [`REQUIREMENTS.md`](./REQUIREMENTS.md)
- Completed status: [`STATUS.md`](./STATUS.md)

## Run (local mode — works today)

```bash
cd fpl_fees
flutter run
```

- **Admin password:** `fpladmin`
- Data is stored on device (`SharedPreferences`) until Firebase is wired.

## What works now

### Admin
- Dashboard (week picker, paid/unpaid, finance total)
- Fees: mark ₹50 / ₹750 subscription / guest ₹200
- Lifetime members pre-seeded (Azhar, Mashood, Nowfal, Mansoor, Bava) — no fee
- Eligible list + copy for WhatsApp → use before CricHeroes selection
- Finance: season total by weekly / subscription / guest / trade commission
- Scorecards: add match summary from CricHeroes PDF
- Trades: enable trade window → record sale (25% commission)
- Edit player **phone** and **CricHeroes username** (More → contacts)

### Player
- Login with **phone** OR **username** (no OTP, case-insensitive username)
- Home: eligibility + UPI `marmuazhar@ybl`
- My team, scorecards, profile

## Seed phones / usernames

1. Login as admin
2. More → Edit player phones / usernames
3. Or share a CSV and we can bulk-import later

Default username = player display name (so “Anas” works immediately).

## Firebase (later)

1. Create Firebase project
2. `dart pub global activate flutterfire_cli && flutterfire configure`
3. Set `kFirebaseEnabled = true` in `lib/config.dart`
4. Deploy rules from `firestore.rules`
5. Replace local admin password with Firebase Auth email

## Fees reminder

| Type | Amount |
|------|--------|
| Weekly | ₹50 |
| Season subscription | ₹750 |
| Guest (day only) | ₹200 |
| Trade commission | 25% of sale |
