# FPL Fees App — Requirements

**Product:** Farm Premier League (FPL) Season 2 — fees, CricHeroes eligibility, scorecards, trades, organizer finance  
**Stack (target):** Flutter mobile + Firebase (Auth, Firestore, Storage)  
**Repo:** https://github.com/azharmarmu/fpl_fees  
**Last confirmed:** 1 Aug 2026

---

## 1. Purpose

Admin marks who paid (cash/UPI outside the app). Captains use an **eligible players list** before adding anyone in CricHeroes. Players can log in (view-only) to see team, fee status, scorecards, and where to pay.

Scoring stays on **CricHeroes**. This app does not replace CricHeroes selection or scoring.

---

## 2. Season context

| Item | Value |
|------|--------|
| Season | FPL Season 2 |
| Start | Sun **2 Aug 2026** |
| Final day | Sun **27 Dec 2026** |
| Cadence | Every Sunday; each team min **2 matches** |
| League Sundays | **21** FPL league days (VPL week separate) |
| VPL Season 2 | 1 week TBA (placeholder **8 Nov 2026** / Diwali) |
| Format (league) | 10 overs, 8-a-side (ops rules outside this app) |

### Teams & captains

| Team ID | Team | Captain |
|---------|------|---------|
| `ox` | OX CC | Anas |
| `gb` | Gully Blasters | Azhar Marmu |
| `new` | Rusfi XI | M S Rusfi |

Squad size ~50 auction players (seeded in app). Phones filled later by admin.

---

## 3. Fee rules (confirmed)

| Type | Amount | Notes |
|------|--------|--------|
| Weekly | **₹50** / league Sunday | Ground fee included |
| Season subscription | **₹750** upfront | Covers all **21** FPL league Sundays + **VPL ground fee** |
| Guest (day only) | **₹200** | That day only; never permanent squad |
| Trade commission | **25%** of sale price | After VPL trade window; to organizer |
| Lifetime members | **₹0** | Always eligible / exempt |

### Lifetime exempt (seeded)

- Azhar Marmu  
- Mashood A C  
- Nowfal  
- Mansoor Vk  
- Bava Kvs  

### Ground / club split (ops, not enforced in app)

- Ground owner (Ali MCK): **₹1,000 / week**  
- Remainder of collections → awards & gifts  

### Eligibility for CricHeroes

A player (or guest) may be added in CricHeroes for the selected Sunday if **any** of:

1. Lifetime member  
2. Season subscription paid  
3. Weekly ₹50 paid for that week  
4. Guest ₹200 recorded for that week  

**Policy:** Must be paid **before the day** or **before the match starts**. If unpaid → cannot be added in the app / cannot play.

Subscription math note for players: 21 × ₹50 = ₹1,050 weekly vs ₹750 sub (save ₹300 + free VPL ground fee).

---

## 4. Roles & auth

### Decisions

| Decision | Choice |
|----------|--------|
| Who marks fees | **Admin only** |
| Payment recording | **Manual only** (cash/UPI outside app) |
| Player login | **Phone OR CricHeroes username** (no OTP; username **case-insensitive**) |
| Admin login (v1 local) | Shared password; Firebase email/password later |

### Admin capabilities

- Dashboard for selected Sunday (paid/unpaid, finance, shortcuts)
- Mark weekly ₹50, toggle ₹750 subscription, add/remove guests ₹200
- Eligible list + **copy for WhatsApp** (for captains)
- Finance ledger (season totals + week-wise)
- Scorecards: add match summary (+ PDF path planned for Firebase)
- Trades: open window after VPL → record sale (25% commission, collect flag)
- Edit player **phone** and **CricHeroes username**
- Seed / maintain squad, captains, lifetime flags

### Player capabilities (view-only)

- Login with phone **or** username
- See own eligibility / fee status
- See pay-to UPI: **`marmuazhar@ybl`** (copy / open UPI)
- My team roster
- Browse scorecards
- Profile (team, subscription/lifetime/weekly status)

Players **cannot** mark payments or change eligibility.

---

## 5. Admin flows

### Dashboard (first screen)

- Season phase / selected Sunday (default upcoming)
- Summary tiles: Fees today · Eligible · Finance · Scorecards / Trades
- Quick actions: mark payments, add guest, upload scorecard, copy eligible

### Normal Sunday

1. **Fees** → tick who paid ₹50 (subscription/lifetime already OK)  
2. Add **guest** if any (₹200)  
3. **Eligible** → Copy → send to captains → add only those in CricHeroes  
4. After matches → **Matches** → enter result (+ attach CricHeroes PDF when Storage wired)

### Other

- **Contacts / Squad** — phones, usernames, lifetime, subscription  
- **Finance** — money received overview  
- **Trades** — only after VPL; enable window in More  

---

## 6. Finance (organizer ledger)

Track **all money received** across the tournament:

- Weekly fees (₹50) — week by week  
- Subscriptions (₹750)  
- Guest fees (₹200)  
- Trade commission (25%)  

Show **season total** + breakdown by type + week-wise list.  
Marking Paid is still manual after UPI/cash confirmation — **no automatic UPI verification in v1**.

---

## 7. Scorecards

- Source of truth: CricHeroes PDF / match result  
- v1: admin enters **match summary** (teams, scores, date, optional notes/PDF reference)  
- Players browse list in-app  
- Full automatic PDF table parse: **out of scope for v1** (optional later)

---

## 8. Trades (post-VPL)

- Trade window closed by default; admin enables after VPL  
- Record: player, from team → to team, sale price  
- Auto-calc commission = **25%** of sale  
- Flag commission collected  
- Update player `teamId` / team name on roster  

---

## 9. Data model (logical)

| Collection / entity | Purpose |
|---------------------|---------|
| `players` | id, name, teamId, phone, cricheroesUsername, lifetime, captain, subscriptionPaid |
| `weeks` | id (YYYY-MM-DD), date, label, isVpl, isLeague |
| `payments` | weekly ₹50 per player per week |
| `guestPayments` | guest ₹200 for a week |
| `matches` | scorecard summaries |
| `trades` | sale + commission |
| `appConfig` | tradeOpen, UPI id/name |
| `admins` | Firebase UIDs (when Auth enabled) |

### Firestore security (target)

- Admin write via `admins/{uid}`  
- Player-facing reads open enough for phone/username lookup (no OTP)  
- Tighten later if needed  

---

## 10. Non-functional / product constraints

- Must be usable **on Sunday mornings** (fast mark + copy eligible)  
- Local-first acceptable until Firebase is configured  
- Online payment gateways (Razorpay etc.): **not in v1**  
- Captains do **not** get write access in v1 (eligible list is shareable text)  

---

## 11. Out of scope (v1)

- In-app UPI collection / payment gateway  
- OTP / SMS verification  
- Auto PDF batting/bowling table parse  
- Captain write roles  
- Auction / retention (separate `fpl_auction` app)  
- Live scoring  

---

## 12. Acceptance checklist

- [ ] Admin can mark weekly / subscription / guest for a Sunday  
- [ ] Eligible list matches fee rules (lifetime, sub, weekly, guest)  
- [ ] Eligible list copyable for WhatsApp  
- [ ] Finance totals match recorded payments + commissions  
- [ ] Player login by phone or username (case-insensitive)  
- [ ] Player sees UPI `marmuazhar@ybl`  
- [ ] Scorecard add + browse  
- [ ] Trades after window open; 25% commission; roster team updates  
- [ ] Season weeks Aug 2 – Dec 27 2026 with VPL placeholder  
- [ ] Firebase optional behind config flag  

---

## 13. Related ops references

- Auction sheet / Apps Script: separate Season 2 auction tooling  
- Spreadsheet & auction app are **not** this repo; fees app owns eligibility + money ledger for match days  
