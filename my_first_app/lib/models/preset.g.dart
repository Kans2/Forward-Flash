// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preset.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PresetAdapter extends TypeAdapter<Preset> {
  @override
  final int typeId = 0;

  @override
  Preset read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Preset(
      id: fields[0] as String,
      name: fields[1] as String,
      emoji: fields[2] as String,
      forwardNumber: fields[3] as String,
      simSlot: fields[4] as int,
      forwardTypeIndex: fields[5] as int,
      isActive: fields[6] as bool,
      lastActivatedAt: fields[7] as String?,
      description: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Preset obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.emoji)
      ..writeByte(3)
      ..write(obj.forwardNumber)
      ..writeByte(4)
      ..write(obj.simSlot)
      ..writeByte(5)
      ..write(obj.forwardTypeIndex)
      ..writeByte(6)
      ..write(obj.isActive)
      ..writeByte(7)
      ..write(obj.lastActivatedAt)
      ..writeByte(8)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
