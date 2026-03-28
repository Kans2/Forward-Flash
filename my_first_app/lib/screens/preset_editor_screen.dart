import 'package:flutter/material.dart';
import '../models/preset.dart';
import '../services/ussd_database.dart';
import '../services/sim_detection_service.dart';

class PresetEditorScreen extends StatefulWidget {
  final Preset preset;
  const PresetEditorScreen({super.key, required this.preset});

  @override
  State<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends State<PresetEditorScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _numberCtrl;
  late ForwardType _fwdType;
  late int _simSlot;
  late String _emoji;

  final _emojis = ['📞','🏢','🔋','🏖️','🤝','🚗','🏠','🎯','⚡','🔕'];

  @override
  void initState() {
    super.initState();
    _nameCtrl   = TextEditingController(text: widget.preset.name);
    _numberCtrl = TextEditingController(text: widget.preset.forwardNumber);
    _fwdType    = widget.preset.forwardType;
    _simSlot    = widget.preset.simSlot;
    _emoji      = widget.preset.emoji;
  }

  Future<void> _save() async {
    if (_numberCtrl.text.trim().isEmpty || _nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and number are required')),
      );
      return;
    }
    widget.preset
      ..name          = _nameCtrl.text.trim()
      ..forwardNumber = _numberCtrl.text.trim()
      ..emoji         = _emoji
      ..forwardTypeIndex = _fwdType.index
      ..simSlot       = _simSlot;
    await PresetRepository.instance.save(widget.preset);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sims   = SimDetectionService.instance.slots;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit preset'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Emoji picker
          Text('Icon', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _emojis.map((e) => GestureDetector(
              onTap: () => setState(() => _emoji = e),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: e == _emoji
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: e == _emoji ? scheme.primary : Colors.transparent,
                  ),
                ),
                child: Center(child: Text(e, style: const TextStyle(fontSize: 22))),
              ),
            )).toList(),
          ),
          const SizedBox(height: 24),

          // Name
          Text('Name', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              hintText: 'e.g. Office mode',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
            ),
          ),
          const SizedBox(height: 20),

          // Forward number
          Text('Forward to', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _numberCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '+91 98765 43210',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
              helperText: '10-digit or +91 format',
            ),
          ),
          const SizedBox(height: 20),

          // Forward type
          Text('When to forward', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          ...ForwardType.values.map((t) => RadioListTile<ForwardType>(
            value: t,
            groupValue: _fwdType,
            onChanged: (v) => setState(() => _fwdType = v!),
            title: Text(CarrierUssdDatabase.forwardTypeLabel(t)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          )),
          const SizedBox(height: 20),

          // SIM slot
          if (sims.length > 1) ...[
            Text('SIM slot', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            ...sims.map((s) => RadioListTile<int>(
              value: s.slotIndex,
              groupValue: _simSlot,
              onChanged: (v) => setState(() => _simSlot = v!),
              title: Text('${s.slotLabel} — ${s.displayName}'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            )),
          ],
        ],
      ),
    );
  }
}