import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

import '../models/preset.dart';
import '../services/call_forwarding_service.dart';
import '../services/sim_detection_service.dart';
import '../widgets/sim_badge.dart';
import '../widgets/status_card.dart';
import '../widgets/preset_card.dart';
import 'preset_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Preset> _presets = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  void _loadPresets() {
    setState(() => _presets = PresetRepository.instance.all().where((p) => p.id != 'adhoc').toList());
  }

  Future<void> _activatePreset(Preset p) async {
    // If the number is empty or too short (e.g. they entered a space or 1 digit),
    // force them to the editor to set it up properly.
    if (p.forwardNumber.trim().length < 3) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please enter a valid forward number first'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      // Prompt to configure
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: p)),
      );
      if (result == true) _loadPresets();
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await CallForwardingService.instance.enable(p);

      if (mounted) {
        setState(() {
          _loading = false;
          _loadPresets();
        });

        if (result.success) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Call Forwarding'),
                ],
              ),
              content: Text(
                'Dialer has been launched to forward calls to ${p.forwardNumber}. '
                'Please verify the success message from your carrier on the screen.',
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Got it'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: ${result.errorMessage}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _deactivate() async {
    setState(() => _loading = true);
    await CallForwardingService.instance.disable();
    setState(() {
      _loading = false;
      _loadPresets();
    });
  }

  Future<void> _showAdHocForwardDialog() async {
    final TextEditingController numberCtrl = TextEditingController();
    bool confirmed = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forward Calls'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the number you want to forward all calls to:'),
            const SizedBox(height: 16),
            TextField(
              controller: numberCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'e.g. 98765 43210',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              confirmed = true;
              Navigator.pop(context);
            },
            child: const Text('Forward Call'),
          ),
        ],
      ),
    );

    if (confirmed && numberCtrl.text.trim().isNotEmpty) {
      final p = Preset(
        id: 'adhoc',
        name: 'Manual Forward',
        emoji: '📞',
        forwardNumber: numberCtrl.text.trim(),
        forwardTypeIndex: 0, // 0 = allCalls
      );
      await PresetRepository.instance.save(p);
      _activatePreset(p);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sims   = SimDetectionService.instance.slots;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App bar ─────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CallForward',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  Row(
                    children: sims.map((s) => SimBadge(slot: s)).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {}, // settings screen
              ),
              const SizedBox(width: 8),
            ],
          ),

          // ── Status card ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeInDown(
              duration: const Duration(milliseconds: 400),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: StatusCard(
                  status: CallForwardingService.instance.status,
                  activePresetId: CallForwardingService.instance.activePreset,
                  onDisable: _deactivate,
                  loading: _loading,
                ),
              ),
            ),
          ),

          // ── Section header ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Presets',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                  TextButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PresetEditorScreen(
                            preset: Preset(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              name: '',
                              emoji: '📞',
                              forwardNumber: '',
                            ),
                          ),
                        ),
                      );
                      if (result == true) _loadPresets();
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New'),
                  ),
                ],
              ),
            ),
          ),

          // ── Presets grid ─────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => FadeInUp(
                  delay: Duration(milliseconds: 60 * i),
                  duration: const Duration(milliseconds: 350),
                  child: PresetCard(
                    preset: _presets[i],
                    onTap: () => _activatePreset(_presets[i]),
                    onEdit: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PresetEditorScreen(preset: _presets[i]),
                        ),
                      );
                      if (result == true) _loadPresets();
                    },
                  ),
                ),
                childCount: _presets.length,
              ),
            ),
          ),
        ],
      ),

      // ── FAB: Ad-hoc forward ───────────────────────────────────────────────
      floatingActionButton: _loading
          ? const FloatingActionButton(
              onPressed: null,
              child: SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : FloatingActionButton.extended(
              onPressed: _showAdHocForwardDialog,
              icon: const Icon(Icons.forward_to_inbox_rounded),
              label: const Text('Forward Call'),
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
            ),
    );
  }
}