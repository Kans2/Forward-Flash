import 'package:flutter/material.dart';
import '../models/preset.dart';
import '../services/ussd_database.dart';

class PresetCard extends StatelessWidget {
  final Preset preset;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const PresetCard({
    super.key,
    required this.preset,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final scheme   = Theme.of(context).colorScheme;
    final isActive = preset.isActive;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isActive ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: emoji + edit button ────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(preset.emoji, style: const TextStyle(fontSize: 28)),
                  GestureDetector(
                    onTap: onEdit,
                    child: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.7)
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // ── Preset name ─────────────────────────────────────────────
              Text(
                preset.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : scheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // ── Forward type chip ────────────────────────────────────────
              Text(
                CarrierUssdDatabase.forwardTypeLabel(preset.forwardType),
                style: TextStyle(
                  fontSize: 11,
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.75)
                      : scheme.onSurfaceVariant,
                ),
              ),

              // ── Forward number (if set) ──────────────────────────────────
              if (preset.forwardNumber.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '→ ${preset.forwardNumber}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.75)
                        : scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}