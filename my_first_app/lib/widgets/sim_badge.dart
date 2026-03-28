import 'package:flutter/material.dart';
import '../services/sim_detection_service.dart';
import '../services/ussd_database.dart';

class SimBadge extends StatelessWidget {
  final SimSlot slot;

  const SimBadge({super.key, required this.slot});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(right: 6, bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${slot.slotLabel} · ${CarrierUssdDatabase.carrierDisplayName(slot.carrier)}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}