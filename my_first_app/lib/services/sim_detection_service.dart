import 'package:flutter/services.dart';
import 'ussd_database.dart';

class SimSlot {
  final int slotIndex;          // 0 = SIM1, 1 = SIM2
  final String? phoneNumber;
  final String? carrierName;
  final String? mccMnc;
  final Carrier carrier;
  final bool isActive;

  const SimSlot({
    required this.slotIndex,
    this.phoneNumber,
    this.carrierName,
    this.mccMnc,
    required this.carrier,
    required this.isActive,
  });

  String get displayName => carrierName ?? CarrierUssdDatabase.carrierDisplayName(carrier);
  String get slotLabel   => slotIndex == 0 ? 'SIM 1' : 'SIM 2';

  @override
  String toString() => '$slotLabel: $displayName ${phoneNumber ?? ""}';
}

class SimDetectionService {
  static const _channel = MethodChannel('com.callforward/sim');

  static SimDetectionService? _instance;
  SimDetectionService._();
  static SimDetectionService get instance => _instance ??= SimDetectionService._();

  List<SimSlot> _slots = [];
  List<SimSlot> get slots => List.unmodifiable(_slots);
  bool get isDualSim => _slots.length >= 2;

  /// Call once on app start (requires READ_PHONE_STATE permission)
  Future<void> init() async {
    try {
      final List<dynamic> rawSlots = await _channel.invokeMethod('getSimSlots');
      _slots = rawSlots.map((s) {
        final map = Map<String, dynamic>.from(s as Map);
        final mccMnc = map['mccMnc'] as String?;
        final name   = map['carrierName'] as String?;
        final carrier = CarrierUssdDatabase.detectCarrierFromMccMnc(mccMnc) != Carrier.unknown
            ? CarrierUssdDatabase.detectCarrierFromMccMnc(mccMnc)
            : CarrierUssdDatabase.detectCarrierFromName(name);
        return SimSlot(
          slotIndex:   map['slotIndex'] as int,
          phoneNumber: map['phoneNumber'] as String?,
          carrierName: name,
          mccMnc:      mccMnc,
          carrier:     carrier,
          isActive:    map['isActive'] as bool? ?? true,
        );
      }).toList();
    } on PlatformException catch (e) {
      // Fallback: single unknown SIM
      _slots = [
        SimSlot(slotIndex: 0, carrier: Carrier.unknown, isActive: true,
                carrierName: 'Unknown carrier'),
      ];
      // ignore: avoid_print
      print('SimDetectionService init error: $e');
    }
  }

  SimSlot? get primarySim => _slots.isNotEmpty ? _slots[0] : null;
  SimSlot? get secondarySim => _slots.length > 1 ? _slots[1] : null;

  SimSlot? slotFor(int index) =>
      _slots.firstWhere((s) => s.slotIndex == index, orElse: () => _slots.first);
}