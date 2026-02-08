// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsAdapter extends TypeAdapter<Settings> {
  @override
  final typeId = 4;

  @override
  Settings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Settings(
      weeklyWorkHours: fields[0] == null ? 40 : (fields[0] as num).toDouble(),
      mondayWorkHours: fields[1] == null ? 8 : (fields[1] as num).toDouble(),
      tuesdayWorkHours: fields[2] == null ? 8 : (fields[2] as num).toDouble(),
      wednesdayWorkHours: fields[3] == null ? 8 : (fields[3] as num).toDouble(),
      thursdayWorkHours: fields[4] == null ? 8 : (fields[4] as num).toDouble(),
      fridayWorkHours: fields[5] == null ? 8 : (fields[5] as num).toDouble(),
      saturdayWorkHours: fields[6] == null ? 0 : (fields[6] as num).toDouble(),
      sundayWorkHours: fields[7] == null ? 0 : (fields[7] as num).toDouble(),
      maxDailyWorkHours: fields[8] == null ? 10 : (fields[8] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, Settings obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.weeklyWorkHours)
      ..writeByte(1)
      ..write(obj.mondayWorkHours)
      ..writeByte(2)
      ..write(obj.tuesdayWorkHours)
      ..writeByte(3)
      ..write(obj.wednesdayWorkHours)
      ..writeByte(4)
      ..write(obj.thursdayWorkHours)
      ..writeByte(5)
      ..write(obj.fridayWorkHours)
      ..writeByte(6)
      ..write(obj.saturdayWorkHours)
      ..writeByte(7)
      ..write(obj.sundayWorkHours)
      ..writeByte(8)
      ..write(obj.maxDailyWorkHours);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
