import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ussd_database.dart';
import 'sim_detection_service.dart';
import '../models/preset.dart';

enum ForwardStatus { unknown, active, inactive, pending }

class ForwardResult {
  final bool success;
  final String? ussdSent;
  final String? errorMessage;

  const ForwardResult({required this.success, this.ussdSent, this.errorMessage});
}

class CallForwardingService {
  static const _channel = MethodChannel('com.callforward/ussd');

  static CallForwardingService? _instance;
  CallForwardingService._();
  static CallForwardingService get instance => _instance ??= CallForwardingService._();

  ForwardStatus _status = ForwardStatus.unknown;
  String?       _activePresetId;

  ForwardStatus get status       => _status;
  String?       get activePreset => _activePresetId;

  // ── Enable forwarding ────────────────────────────────────────────────────
  Future<ForwardResult> enable(Preset preset) async {
    if (preset.forwardNumber.isEmpty) {
      return const ForwardResult(success: false, errorMessage: 'No forward number set');
    }

    final sim = SimDetectionService.instance.slotFor(preset.simSlot);
    final ussd = CarrierUssdDatabase.buildEnable(
      preset.forwardType,
      preset.forwardNumber,
      carrier: sim?.carrier ?? Carrier.unknown,
    );

    final result = await _dialUssd(ussd, simSlot: preset.simSlot);
    if (result.success) {
      _status = ForwardStatus.active;
      _activePresetId = preset.id;
      preset.lastActivatedAt = DateTime.now().toIso8601String();
      await preset.save();
      await PresetRepository.instance.setActive(preset.id);
    }
    return ForwardResult(success: result.success, ussdSent: ussd, errorMessage: result.errorMessage);
  }

  // ── Disable forwarding ───────────────────────────────────────────────────
  Future<ForwardResult> disable({int simSlot = 0, bool allTypes = true}) async {
    final ussd = allTypes
        ? CarrierUssdDatabase.disableAll()
        : CarrierUssdDatabase.buildDisable(ForwardType.allCalls);

    final result = await _dialUssd(ussd, simSlot: simSlot);
    if (result.success) {
      _status = ForwardStatus.inactive;
      _activePresetId = null;
      await PresetRepository.instance.setActive(null);
    }
    return ForwardResult(success: result.success, ussdSent: ussd, errorMessage: result.errorMessage);
  }

  // ── Check status (fire-and-forget USSD, parse response if available) ─────
  Future<ForwardStatus> checkStatus({int simSlot = 0}) async {
    const ussd = '##21#'; // GSM universal check
    await _dialUssd(ussd, simSlot: simSlot);
    return _status;
  }

  // ── Core dialer ──────────────────────────────────────────────────────────
  Future<({bool success, String? errorMessage})> _dialUssd(
    String ussd, {
    int simSlot = 0,
    bool silent = false,
  }) async {
    debugPrint('[CallForward] _dialUssd called: ussd=$ussd simSlot=$simSlot');

    // Check permission first — gives a clear error instead of silent fail
    final status = await Permission.phone.status;
    if (!status.isGranted) {
      final result = await Permission.phone.request();
      if (!result.isGranted) {
        debugPrint('[CallForward] Phone permission denied');
        return (
          success: false,
          errorMessage: 'Phone permission denied. Go to Settings → Apps → my_first_app → Permissions and enable Phone.'
        );
      }
    }

    try {
      // Try native platform channel first (supports SIM slot selection)
      debugPrint('[CallForward] Invoking native dialUssd channel');
      final ok = await _channel.invokeMethod<bool>('dialUssd', {
        'ussd':    ussd,
        'simSlot': simSlot,
        'silent':  silent,
      });
      debugPrint('[CallForward] Native channel returned: $ok');
      return (success: ok ?? false, errorMessage: null);
    } on PlatformException catch (e) {
      debugPrint('[CallForward] PlatformException: ${e.message}, trying fallback');
      // Fallback: open dialer directly via tel: URI
      // IMPORTANT: only encode '#' → '%23'; leave '*' unencoded or USSD breaks.
      try {
        // FlutterPhoneDirectCaller expects a raw dial string, NOT a tel: URI.
        // Encode '#' → '%23' so the dialer interprets it correctly.
        final encoded = ussd.replaceAll('#', '%23');
        final ok = await FlutterPhoneDirectCaller.callNumber(encoded) ?? false;
        debugPrint('[CallForward] Fallback result: $ok');
        return (success: ok, errorMessage: ok ? null : 'Dialler fallback failed');
      } catch (fallbackErr) {
        debugPrint('[CallForward] Fallback error: $fallbackErr');
        return (success: false, errorMessage: e.message ?? 'USSD dial failed');
      }
    }
  }
}