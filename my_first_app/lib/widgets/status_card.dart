import 'package:flutter/material.dart';
import '../services/call_forwarding_service.dart';
import '../models/preset.dart';

class StatusCard extends StatelessWidget {
  final ForwardStatus status;
  final String? activePresetId;
  final VoidCallback onDisable;
  final bool loading;

  const StatusCard({
    super.key,
    required this.status,
    this.activePresetId,
    required this.onDisable,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme  = Theme.of(context).colorScheme;
    final isActive = status == ForwardStatus.active;
    final preset  = activePresetId != null
        ? PresetRepository.instance.get(activePresetId!)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary,
                  scheme.primaryContainer,
                ],
              )
            : null,
        color: isActive ? null : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.2)
                  : scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isActive ? Colors.white : scheme.primary,
                      ),
                    )
                  : Icon(
                      isActive
                          ? Icons.forward_to_inbox_rounded
                          : Icons.phone_disabled_outlined,
                      color: isActive ? Colors.white : scheme.onSurfaceVariant,
                      size: 26,
                    ),
            ),
          ),
          const SizedBox(width: 16),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? 'Forwarding active' : 'Forwarding off',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isActive && preset != null
                      ? '${preset.emoji} ${preset.name} → ${preset.forwardNumber}'
                      : isActive
                          ? 'Active'
                          : 'Tap a preset to enable',
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.8)
                        : scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Disable button
          if (isActive)
            TextButton(
              onPressed: loading ? null : onDisable,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Stop', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}