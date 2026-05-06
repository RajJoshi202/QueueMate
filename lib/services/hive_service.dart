import 'package:hive/hive.dart';
import '../models/appointment_model.dart';

/// HiveService handles all local storage operations using Hive.
/// Provides CRUD operations for appointments stored in a local Hive box.
/// This serves as the offline-first data layer.
class HiveService {
  static const String _boxName = 'appointments';

  /// Gets the opened Hive box for appointments.
  Box<Appointment> get _box => Hive.box<Appointment>(_boxName);

  /// Saves a new appointment to the local Hive box.
  /// Uses the appointment ID as the key for easy lookup.
  Future<void> saveAppointment(Appointment appointment) async {
    await _box.put(appointment.id, appointment);
  }

  /// Retrieves all appointments from the local Hive box.
  /// Returns an empty list if no appointments exist.
  List<Appointment> getAllAppointments() {
    return _box.values.toList();
  }

  /// Updates an existing appointment in the local Hive box.
  /// Finds the appointment by its ID and replaces it.
  Future<void> updateAppointment(Appointment appointment) async {
    await _box.put(appointment.id, appointment);
  }

  /// Deletes an appointment from the local Hive box by its ID.
  Future<void> deleteAppointment(String id) async {
    await _box.delete(id);
  }

  /// Retrieves all appointments that haven't been synced to Firestore yet.
  /// These are appointments where synced == false, meaning they exist
  /// only locally and need to be pushed to the cloud.
  List<Appointment> getUnsyncedAppointments() {
    return _box.values.where((a) => !a.synced).toList();
  }
}
