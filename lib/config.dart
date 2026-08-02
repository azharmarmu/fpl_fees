import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

/// Display name shown on home screen / store listings.
const kAppName = 'FPL';

/// Brand mark used in login and marketing surfaces.
const kAppLogoAsset = 'assets/images/fpl_logo.png';

/// Default fee amounts (INR). Admin can override via More → Fee amounts.
const kWeeklyFee = 50;
const kSubscriptionFee = 750;
const kGuestFee = 200;
const kTradeCommissionRate = 0.25;

const kUpiId = 'marmuazhar@ybl';
const kUpiDisplayName = 'Azhar Marmu';

const kTeamOx = 'ox';
const kTeamGb = 'gb';
const kTeamAvengers = 'avengers';

/// Floating / guest player — not on a squad; lifetime members here pay no fees.
const kTeamGuest = 'guest';

/// Legacy id used in early Season 2 data — migrated to [kTeamAvengers] on load.
const kTeamNewLegacy = 'new';

const kTeamNames = {
  kTeamOx: 'OX CC',
  kTeamGb: 'Gully Blasters',
  kTeamAvengers: 'Farm Avengers CC',
  kTeamGuest: 'Guest',
};

/// Local admin gate when Firebase Auth is not configured.
const kLocalAdminPassword = 'fpladmin';

/// Firebase Auth email used only as a debug convenience default in the login UI.
/// Release builds never prefill this — admin must type email.
const kFirebaseAdminEmail = 'marmuazhardev@gmail.com';

/// Flip to true after `flutterfire configure` replaces firebase_options.dart.
const kFirebaseEnabled = true;

/// Allow Firebase on web (Hosting + Chrome). Same Firestore as mobile.
const kAllowFirebaseOnWeb = true;

/// True when flag is on, options are real, and platform is supported.
bool get wantsFirebase {
  if (!kFirebaseEnabled) return false;
  if (!DefaultFirebaseOptions.configured) return false;
  if (kIsWeb && !kAllowFirebaseOnWeb) return false;
  return true;
}
