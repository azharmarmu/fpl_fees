#!/usr/bin/env python3
"""Create VPL auction registration Payment Links (₹300 / ₹200 / ₹100) via Razorpay API.

Usage (live keys from Dashboard → Account & Settings → API Keys):
  export RAZORPAY_KEY_ID=rzp_live_...
  export RAZORPAY_KEY_SECRET=...
  python3 scripts/create_vpl_razorpay_links.py

Optional:
  RAZORPAY_EXPIRE_BY=1793298599  # Unix seconds (default: 29 Oct 2026 23:59 IST)
"""

from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone

API = "https://api.razorpay.com/v1/payment_links/"

SLOTS = (
    (300, "VPL Auction Registration — ₹300 slot"),
    (200, "VPL Auction Registration — ₹200 slot"),
    (100, "VPL Auction Registration — ₹100 slot"),
)


def default_expire_by() -> int:
    ist = timezone(timedelta(hours=5, minutes=30))
    end = datetime(2026, 10, 29, 23, 59, 59, tzinfo=ist)
    return int(end.timestamp())


def create_link(key_id: str, key_secret: str, amount_rupees: int, description: str, expire_by: int) -> dict:
    payload = {
        "amount": amount_rupees * 100,
        "currency": "INR",
        "description": description,
        "reference_id": f"VPL-AUCTION-2026-{amount_rupees}",
        "expire_by": expire_by,
        "reminder_enable": True,
        "notes": {
            "event": "VPL Week 15 auction",
            "slot_inr": str(amount_rupees),
        },
    }
    body = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(API, data=body, method="POST")
    req.add_header("Content-Type", "application/json")
    password_mgr = urllib.request.HTTPPasswordMgrWithDefaultRealm()
    password_mgr.add_password(None, API, key_id, key_secret)
    opener = urllib.request.build_opener(urllib.request.HTTPBasicAuthHandler(password_mgr))
    with opener.open(req, timeout=60) as resp:
        return json.loads(resp.read().decode("utf-8"))


def main() -> int:
    key_id = os.environ.get("RAZORPAY_KEY_ID", "").strip()
    key_secret = os.environ.get("RAZORPAY_KEY_SECRET", "").strip()
    if not key_id or not key_secret:
        print(
            "Missing RAZORPAY_KEY_ID or RAZORPAY_KEY_SECRET.\n"
            "Get live keys: Razorpay Dashboard → Account & Settings → API Keys → Generate.",
            file=sys.stderr,
        )
        return 1

    expire_by = int(os.environ.get("RAZORPAY_EXPIRE_BY", str(default_expire_by())))

    print("Creating Payment Links (live API)…\n")
    links: list[tuple[int, str]] = []

    for amount, desc in SLOTS:
        try:
            data = create_link(key_id, key_secret, amount, desc, expire_by)
        except urllib.error.HTTPError as e:
            err = e.read().decode("utf-8", errors="replace")
            print(f"₹{amount}: HTTP {e.code}\n{err}\n", file=sys.stderr)
            return 1
        short_url = data.get("short_url")
        if not short_url:
            print(f"₹{amount}: unexpected response:\n{json.dumps(data, indent=2)}", file=sys.stderr)
            return 1
        links.append((amount, short_url))
        print(f"₹{amount}: {short_url}")
        print(f"         id: {data.get('id', '')}\n")

    print("--- WhatsApp (copy below) ---\n")
    print("VPL auction registration — pay only via these links (not to any personal number):\n")
    for amount, url in links:
        print(f"₹{amount} slot: {url}")
    print("\nPayment required before 30 Oct auction. Unpaid names will not be called.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
