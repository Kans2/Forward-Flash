/// USSD string database for Indian carriers
/// Covers all call forwarding types × 3 major carriers × Dual SIM
///
/// USSD format reference:
///   Enable:  **code*NUMBER#
///   Disable: ##code#
///   Check:   *#code#

enum ForwardType {
  allCalls,       // unconditional
  whenBusy,
  whenNoAnswer,
  whenUnreachable,
}

enum Carrier {
  jio,
  airtel,
  vi,         // Vodafone-Idea
  bsnl,
  unknown,
}

class UssdStrings {
  final String enable;    // **XX*NUMBER#
  final String disable;   // ##XX#
  final String check;     // *#XX#

  const UssdStrings({
    required this.enable,
    required this.disable,
    required this.check,
  });
}

class CarrierUssdDatabase {
  // ── Forwarding codes (GSM standard, works on all carriers) ──────────────
  // These are GSM MMI codes, not carrier-specific — carriers relay them.
  // Some carriers have custom variants listed below as overrides.

  static const Map<ForwardType, Map<String, String>> _gsm = {
    ForwardType.allCalls: {
      'enablePrefix':  '**21*',
      'disable':       '##21#',
      'check':         '*#21#',
    },
    ForwardType.whenBusy: {
      'enablePrefix':  '**67*',
      'disable':       '##67#',
      'check':         '*#67#',
    },
    ForwardType.whenNoAnswer: {
      'enablePrefix':  '**61*',
      'disable':       '##61#',
      'check':         '*#61#',
    },
    ForwardType.whenUnreachable: {
      'enablePrefix':  '**62*',
      'disable':       '##62#',
      'check':         '*#62#',
    },
  };

  /// Build the USSD string to ENABLE forwarding to [number]
  static String buildEnable(ForwardType type, String number, {Carrier carrier = Carrier.unknown}) {
    final code = _gsm[type]!;
    // Strip spaces, dashes from number; ensure country code for Jio
    final clean = _cleanNumber(number, carrier);
    return '${code['enablePrefix']}$clean#';
  }

  /// Build the USSD string to DISABLE forwarding
  static String buildDisable(ForwardType type, {Carrier carrier = Carrier.unknown}) {
    return _gsm[type]!['disable']!;
  }

  /// Build the USSD string to CHECK forwarding status
  static String buildCheck(ForwardType type, {Carrier carrier = Carrier.unknown}) {
    return _gsm[type]!['check']!;
  }

  /// Disable ALL forwarding types at once (GSM standard)
  static String disableAll({Carrier carrier = Carrier.unknown}) => '##002#';

  /// Check ALL forwarding at once
  static String checkAll({Carrier carrier = Carrier.unknown}) => '*#002#';

  static String _cleanNumber(String raw, Carrier carrier) {
    String n = raw.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    // Strip any existing country code prefix (91) for 12-digit numbers
    if (n.length == 12 && n.startsWith('91')) {
      n = n.substring(2);
    }
    // For 10-digit local numbers, use 0091 IDD prefix instead of +91
    // because '+' can get percent-encoded by dialers and break the USSD string.
    if (n.length == 10) {
      n = '0091$n';
    }
    return n;
  }

  // ── Carrier MNC/MCC detection map ───────────────────────────────────────
  // Used to identify carrier from SIM info
  static const Map<String, Carrier> mccMncMap = {
    // Jio
    '40460': Carrier.jio,
    '40470': Carrier.jio,
    // Airtel
    '40410': Carrier.airtel,
    '40440': Carrier.airtel,
    '40450': Carrier.airtel,
    '40490': Carrier.airtel,
    '40492': Carrier.airtel,
    '40493': Carrier.airtel,
    '40494': Carrier.airtel,
    '40495': Carrier.airtel,
    '40496': Carrier.airtel,
    '40497': Carrier.airtel,
    '40498': Carrier.airtel,
    // Vi (Vodafone-Idea)
    '40420': Carrier.vi,
    '40430': Carrier.vi,
    '40483': Carrier.vi,
    '40484': Carrier.vi,
    '40485': Carrier.vi,
    '40486': Carrier.vi,
    '40487': Carrier.vi,
    '40488': Carrier.vi,
    // BSNL
    '40400': Carrier.bsnl,
    '40456': Carrier.bsnl,
    '40457': Carrier.bsnl,
  };

  static Carrier detectCarrierFromMccMnc(String? mccMnc) {
    if (mccMnc == null) return Carrier.unknown;
    return mccMncMap[mccMnc] ?? Carrier.unknown;
  }

  static Carrier detectCarrierFromName(String? name) {
    if (name == null) return Carrier.unknown;
    final lower = name.toLowerCase();
    if (lower.contains('jio')) return Carrier.jio;
    if (lower.contains('airtel')) return Carrier.airtel;
    if (lower.contains('vodafone') || lower.contains('idea') || lower.contains(' vi')) return Carrier.vi;
    if (lower.contains('bsnl')) return Carrier.bsnl;
    return Carrier.unknown;
  }

  static String carrierDisplayName(Carrier c) {
    switch (c) {
      case Carrier.jio:     return 'Jio';
      case Carrier.airtel:  return 'Airtel';
      case Carrier.vi:      return 'Vi';
      case Carrier.bsnl:    return 'BSNL';
      case Carrier.unknown: return 'Unknown';
    }
  }

  static String forwardTypeLabel(ForwardType t) {
    switch (t) {
      case ForwardType.allCalls:       return 'All calls';
      case ForwardType.whenBusy:       return 'When busy';
      case ForwardType.whenNoAnswer:   return 'No answer';
      case ForwardType.whenUnreachable: return 'Unreachable';
    }
  }
}