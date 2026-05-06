/// App-wide constants for the QueueMate application.
/// Contains configuration values for slot management, admin access,
/// service types, and time slot definitions.

/// Maximum number of appointments allowed per time slot.
const int maxPerSlot = 3;

/// Duration of each time slot in minutes.
const int slotDurationMinutes = 30;

/// Average time to service one appointment in minutes.
const int avgServiceMinutes = 15;

/// Admin PIN for dashboard access.
const String adminPin = '1234';

/// List of available service types for booking.
const List<String> serviceTypes = [
  'Consultation',
  'Haircut',
  'Document Verification',
  'Checkup',
  'Other',
];

/// Pre-generated 30-minute time slots from 9:00 AM to 5:00 PM.
List<String> get timeSlots {
  final slots = <String>[];
  for (int hour = 9; hour < 17; hour++) {
    for (int minute = 0; minute < 60; minute += slotDurationMinutes) {
      final h = hour > 12 ? hour - 12 : hour;
      final amPm = hour >= 12 ? 'PM' : 'AM';
      final m = minute.toString().padLeft(2, '0');
      final hStr = h.toString().padLeft(2, '0');
      slots.add('$hStr:$m $amPm');
    }
  }
  return slots;
}
