import 'package:hive/hive.dart';

part 'appointment_model.g.dart';

/// Appointment model representing a single booking in the QueueMate system.
/// Uses Hive for local storage serialization and provides Firestore map conversion.
@HiveType(typeId: 0)
class Appointment extends HiveObject {
  /// Unique appointment ID in format "APT-XXXXXX"
  @HiveField(0)
  final String id;

  /// User's full name
  @HiveField(1)
  final String name;

  /// Type of service requested (e.g., "Consultation", "Haircut")
  @HiveField(2)
  final String serviceType;

  /// Scheduled date and time for the appointment
  @HiveField(3)
  final DateTime dateTime;

  /// Position in the queue for the given day
  @HiveField(4)
  final int queuePosition;

  /// Current status: "Scheduled", "In Progress", "Completed", "Cancelled"
  @HiveField(5)
  final String status;

  /// Whether this appointment has been synced to Firestore
  @HiveField(6)
  final bool synced;

  Appointment({
    required this.id,
    required this.name,
    required this.serviceType,
    required this.dateTime,
    required this.queuePosition,
    this.status = 'Scheduled',
    this.synced = false,
  });

  /// Converts the Appointment to a Map for Firestore serialization.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'serviceType': serviceType,
      'dateTime': dateTime.toIso8601String(),
      'queuePosition': queuePosition,
      'status': status,
      'synced': synced,
    };
  }

  /// Creates an Appointment from a Firestore document map.
  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] as String,
      name: map['name'] as String,
      serviceType: map['serviceType'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      queuePosition: map['queuePosition'] as int,
      status: map['status'] as String? ?? 'Scheduled',
      synced: map['synced'] as bool? ?? true,
    );
  }

  /// Returns a new Appointment with updated fields (immutable update pattern).
  Appointment copyWith({
    String? id,
    String? name,
    String? serviceType,
    DateTime? dateTime,
    int? queuePosition,
    String? status,
    bool? synced,
  }) {
    return Appointment(
      id: id ?? this.id,
      name: name ?? this.name,
      serviceType: serviceType ?? this.serviceType,
      dateTime: dateTime ?? this.dateTime,
      queuePosition: queuePosition ?? this.queuePosition,
      status: status ?? this.status,
      synced: synced ?? this.synced,
    );
  }

  @override
  String toString() {
    return 'Appointment(id: $id, name: $name, serviceType: $serviceType, '
        'dateTime: $dateTime, queuePosition: $queuePosition, '
        'status: $status, synced: $synced)';
  }
}
