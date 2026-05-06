import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/appointment_model.dart';
import 'constants.dart';

/// Utility functions for the QueueMate application.
/// Contains business logic helpers for slot validation, queue management,
/// ID generation, and date/time operations.

const _uuid = Uuid();

/// Checks if a given time slot is fully booked.
/// A slot is full when the number of non-cancelled appointments
/// at that specific date+time reaches [maxPerSlot].
bool isSlotFull(List<Appointment> appointments, DateTime slot) {
  final count = appointments.where((a) {
    return a.dateTime.year == slot.year &&
        a.dateTime.month == slot.month &&
        a.dateTime.day == slot.day &&
        a.dateTime.hour == slot.hour &&
        a.dateTime.minute == slot.minute &&
        a.status != 'Cancelled';
  }).length;
  return count >= maxPerSlot;
}

/// Checks for duplicate bookings — same name at the same slot that isn't cancelled.
/// Prevents a user from booking the same time slot twice.
bool isDuplicateBooking(
    List<Appointment> appointments, String name, DateTime slot) {
  return appointments.any((a) {
    return a.name.toLowerCase() == name.toLowerCase() &&
        a.dateTime.year == slot.year &&
        a.dateTime.month == slot.month &&
        a.dateTime.day == slot.day &&
        a.dateTime.hour == slot.hour &&
        a.dateTime.minute == slot.minute &&
        a.status != 'Cancelled';
  });
}

/// Calculates the next queue position for a given date.
/// Returns count of non-cancelled appointments on that date + 1.
int getQueuePosition(List<Appointment> appointments, DateTime date) {
  final count = appointments.where((a) {
    return a.dateTime.year == date.year &&
        a.dateTime.month == date.month &&
        a.dateTime.day == date.day &&
        a.status != 'Cancelled';
  }).length;
  return count + 1;
}

/// Estimates the wait time in minutes based on queue position.
/// Calculates the difference between user's position and current token,
/// multiplied by the average service time. Minimum is 0.
int estimatedWaitMinutes(int userPosition, int currentToken) {
  final diff = userPosition - currentToken;
  return diff > 0 ? diff * avgServiceMinutes : 0;
}

/// Generates a unique appointment ID in format "APT-XXXXXX".
/// Uses the first 6 characters of a UUID v4, uppercased.
String generateAppointmentId() {
  final uid = _uuid.v4().replaceAll('-', '').substring(0, 6).toUpperCase();
  return 'APT-$uid';
}

/// Checks if a given DateTime is in the past.
/// Used to prevent booking past date/time slots.
bool isPastDateTime(DateTime dt) {
  return dt.isBefore(DateTime.now());
}

/// Formats a DateTime to a user-friendly date string (e.g., "May 6, 2026").
String formatDate(DateTime dt) {
  return DateFormat('MMM d, yyyy').format(dt);
}

/// Formats a DateTime to a user-friendly time string (e.g., "09:30 AM").
String formatTime(DateTime dt) {
  return DateFormat('hh:mm a').format(dt);
}

/// Formats a DateTime to a full date and time string.
String formatDateTime(DateTime dt) {
  return DateFormat('MMM d, yyyy • hh:mm a').format(dt);
}

/// Parses a time slot string (e.g., "09:30 AM") into hour and minute components.
/// Returns a map with 'hour' and 'minute' keys in 24-hour format.
Map<String, int> parseTimeSlot(String slot) {
  final parts = slot.split(' ');
  final timeParts = parts[0].split(':');
  int hour = int.parse(timeParts[0]);
  final minute = int.parse(timeParts[1]);
  final period = parts[1].toUpperCase();

  if (period == 'PM' && hour != 12) {
    hour += 12;
  } else if (period == 'AM' && hour == 12) {
    hour = 0;
  }

  return {'hour': hour, 'minute': minute};
}
