import 'package:hive/hive.dart';
import '../services/ussd_database.dart';

part 'preset.g.dart';

@HiveType(typeId: 0)
class Preset extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) String emoji;         // visual identity
  @HiveField(3) String forwardNumber; // number to forward to
  @HiveField(4) int    simSlot;       // 0 or 1
  @HiveField(5) int    forwardTypeIndex; // ForwardType.index
  @HiveField(6) bool   isActive;
  @HiveField(7) String? lastActivatedAt;
  @HiveField(8) String? description;

  Preset({
    required this.id,
    required this.name,
    required this.emoji,
    required this.forwardNumber,
    this.simSlot = 0,
    this.forwardTypeIndex = 0, // allCalls
    this.isActive = false,
    this.lastActivatedAt,
    this.description,
  });

  ForwardType get forwardType => ForwardType.values[forwardTypeIndex];

  static List<Preset> defaults() => [
    Preset(
      id: 'office',
      name: 'Office mode',
      emoji: '🏢',
      forwardNumber: '',
      forwardTypeIndex: ForwardType.allCalls.index,
      description: 'Forward to office landline',
    ),
    Preset(
      id: 'battery_low',
      name: 'Battery low',
      emoji: '🔋',
      forwardNumber: '',
      forwardTypeIndex: ForwardType.whenUnreachable.index,
      description: 'Forward to secondary phone',
    ),
    Preset(
      id: 'vacation',
      name: 'Vacation',
      emoji: '🏖️',
      forwardNumber: '',
      forwardTypeIndex: ForwardType.allCalls.index,
      description: 'Forward while on holiday',
    ),
    Preset(
      id: 'busy',
      name: 'In a meeting',
      emoji: '🤝',
      forwardNumber: '',
      forwardTypeIndex: ForwardType.whenBusy.index,
      description: 'Forward when busy',
    ),
  ];
}

class PresetRepository {
  static const _boxName = 'presets';
  static const _activeKey = 'active_preset_id';

  late Box<Preset>    _box;
  late Box<dynamic>   _meta;

  static PresetRepository? _instance;
  PresetRepository._();
  static PresetRepository get instance => _instance ??= PresetRepository._();

  Future<void> init() async {
    Hive.registerAdapter(PresetAdapter());
    _box  = await Hive.openBox<Preset>(_boxName);
    _meta = await Hive.openBox('meta');

    // Seed defaults if first run
    if (_box.isEmpty) {
      for (final p in Preset.defaults()) {
        await _box.put(p.id, p);
      }
    }
  }

  List<Preset> all() => _box.values.toList();

  Preset? get(String id) => _box.get(id);

  Future<void> save(Preset p) => _box.put(p.id, p);

  Future<void> delete(String id) => _box.delete(id);

  String? get activePresetId => _meta.get(_activeKey) as String?;

  Future<void> setActive(String? id) async {
    // Deactivate all
    for (final p in _box.values) {
      p.isActive = id == p.id;
      await p.save();
    }
    await _meta.put(_activeKey, id);
  }
}