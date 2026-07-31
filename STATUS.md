# FPL Fees App — Completed Status

**Repo:** https://github.com/azharmarmu/fpl_fees  
**Branch:** `main`  
**Status date:** 1 Aug 2026  
**Overall:** **v1 local MVP complete** — usable on-device without Firebase. Cloud sync / Auth / PDF storage still pending.

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
| Scorecards (manual summary) | Done |
| Trades (25% commission) | Done |
| Player login (phone / username, no OTP) | Done |
| Player home + UPI | Done |
| Local persistence (SharedPreferences) | Done |
| Firebase Auth / Firestore live | **Not done** (`kFirebaseEnabled = false`) |
| PDF upload to Storage | **Not done** |
| Bulk phone CSV import | **Not done** |
| Online payments | Out of scope v1 |

---

## Done — product features

### Platform

- [x] Flutter project under `fpl_fees/`
- [x] Config constants: fees, UPI, teams, local admin password (`lib/config.dart`)
- [x] Models: players, weeks, payments, guests, matches, trades, eligibility, finance (`lib/models/models.dart`)
- [x] In-memory + SharedPreferences store (`lib/services/fpl_store.dart`)
- [x] Session (admin vs player) (`lib/services/session_service.dart`)
- [x] Firestore rules template (`firestore.rules`) — ready to deploy later
- [x] README with run / admin password / Firebase steps

### Seed data

- [x] 50 Season 2 auction squad players across OX / GB / Rusfi XI
- [x] Captains flagged (Anas, Azhar, M S Rusfi)
- [x] Lifetime members: Azhar, Mashood, Nowfal, Mansoor Vk, Bava Kvs
- [x] Default CricHeroes username = display name
- [x] Weeks Sun **2 Aug 2026 → 27 Dec 2026**; **8 Nov** = VPL placeholder

### Admin

- [x] Login with local password `fpladmin`
- [x] Shell: Home · Fees · Matches · More
- [x] Dashboard: week picker, paid/unpaid counts, finance total, shortcuts
- [x] Fees: mark ₹50 weekly / toggle ₹750 subscription / add guest ₹200
- [x] Eligible screen + copy text for WhatsApp
- [x] Finance: season total by weekly / subscription / guest / trade commission + week-wise
- [x] Add match scorecard summary
- [x] Trades: enable window (More) → record sale → 25% commission + roster team update
- [x] Edit player phone & CricHeroes username (More → contacts)

### Player

- [x] Login phone **or** username (case-insensitive username; no OTP)
- [x] Home: eligibility reason + UPI `marmuazhar@ybl` (copy / open)
- [x] My team
- [x] Scorecards browse
- [x] Profile (lifetime / subscription / weekly)

### Eligibility logic (implemented)

Matches confirmed rules:

1. Lifetime → eligible  
2. Subscription paid → eligible  
3. Weekly ₹50 for selected week → eligible  
4. Guest ₹200 that week → listed as guest eligible  
5. Else unpaid  

---

## Not done / deferred

| Item | Notes |
|------|--------|
| Firebase project + `flutterfire configure` | Flip `kFirebaseEnabled = true` after setup |
| Firebase Auth (admin email) | Replace local password |
| Firestore sync across devices | Today data is **per device** only |
| Firebase Storage PDF attach | Match model supports summary; file upload TBD |
| Auto PDF scorecard parse | Explicitly out of v1 |
| Bulk CSV phone/username import | Manual edit UI exists; CSV later |
| Captain role / write access | Not required (1B admin-only) |
| In-app payment gateway | Out of scope (2A manual) |
| OTP login | Replaced by phone/username lookup |
| Ground ₹1,000/week Ali split report | Ops note only; not a ledger line item |
| App store / Play release | Not started |
| Automated tests beyond smoke widget test | Minimal |

---

## Acceptance vs requirements

| Requirement | Status |
|-------------|--------|
| Admin marks weekly / sub / guest | Done (local) |
| Eligible list matches fee rules | Done |
| Copy eligible for WhatsApp | Done |
| Finance totals by type + week | Done |
| Player phone or username login | Done |
| Show UPI `marmuazhar@ybl` | Done |
| Scorecard add + browse | Done (summary; no cloud PDF) |
| Trades + 25% + roster update | Done |
| Season calendar + VPL week | Done |
| Firebase optional behind flag | Done (flag off) |
| Multi-device shared data | Pending Firebase |

---

## How to run (current)

```bash
cd fpl_fees
flutter run
```

- **Admin password:** `fpladmin`  
- Storage: device SharedPreferences until Firebase is enabled  

---

## Suggested next milestones

1. **Firebase enablement** — project, Auth admin user, deploy `firestore.rules`, turn on `kFirebaseEnabled`  
2. **Seed phones** — bulk import or paste list into contacts  
3. **PDF upload** — Storage + link on match docs  
4. **Hardening** — tighten read rules; backup/export season ledger  
5. **Release** — Android / iOS build for captains & players  

---

## Change log (high level)

| Date | Note |
|------|------|
| 1 Aug 2026 | Initial local MVP committed & pushed to GitHub |
| 1 Aug 2026 | `REQUIREMENTS.md` + `STATUS.md` added for future reference |
