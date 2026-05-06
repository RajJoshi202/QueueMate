// GENERATED CODE - DO NOT MODIFY BY HAND
// This is a manually written Hive TypeAdapter for the Appointment model.
// In production, run `flutter pub run build_runner build` to auto-generate this.

part of 'appointment_model.dart';

/// Hive TypeAdapter for the Appointment model.
/// Handles serialization and deserialization of Appointment objects
/// to and from Hive binary format.
class AppointmentAdapter extends TypeAdapter<Appointment> {
  @override
  final int typeId = 0;

  @override
  Appointment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Appointment(
      id: fields[0] as String,
      name: fields[1] as String,
      serviceType: fields[2] as String,
      dateTime: fields[3] as DateTime,
      queuePosition: fields[4] as int,
      status: fields[5] as String,
      synced: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Appointment obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.serviceType)
      ..writeByte(3)
      ..write(obj.dateTime)
      ..writeByte(4)
      ..write(obj.queuePosition)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.synced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
