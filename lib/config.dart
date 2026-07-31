import 'package:flutter/foundation.dart';

/// Fee constants (INR).
const kWeeklyFee = 50;
const kSubscriptionFee = 750;
const kGuestFee = 200;
const kTradeCommissionRate = 0.25;

const kUpiId = 'marmuazhar@ybl';
const kUpiDisplayName = 'Azhar Marmu';

const kTeamOx = 'ox';
const kTeamGb = 'gb';
const kTeamNew = 'new';

const kTeamNames = {
  kTeamOx: 'OX CC',
  kTeamGb: 'Gully Blasters',
  kTeamNew: 'Rusfi XI',
};

/// Local admin gate when Firebase Auth is not configured.
const kLocalAdminPassword = 'fpladmin';

/// Flip to true after `flutterfire configure`.
const kFirebaseEnabled = false;

bool get wantsFirebase => kFirebaseEnabled && !kIsWeb;
