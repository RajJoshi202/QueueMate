import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

/// FirestoreService handles all cloud Firestore operations.
/// Provides CRUD methods for the 'appointments' collection.
/// All methods are wrapped in try/catch for error handling.
class FirestoreService {
  /// Reference to the Firestore 'appointments' collection.
  final CollectionReference _collection =
      FirebaseFirestore.instance.collection('appointments');

  /// Saves an appointment to Firestore.
  /// Uses the appointment ID as the document ID for easy retrieval.
  Future<void> saveAppointment(Appointment appointment) async {
    try {
      await _collection.doc(appointment.id).set(appointment.toMap());
    } catch (e) {
      print('FirestoreService.saveAppointment error: $e');
      rethrow;
    }
  }

  /// Fetches all appointments from Firestore.
  /// Returns a list of Appointment objects parsed from document data.
  Future<List<Appointment>> getAllAppointments() async {
    try {
      final snapshot = await _collection.get();
      return snapshot.docs.map((doc) {
        return Appointment.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('FirestoreService.getAllAppointments error: $e');
      return [];
    }
  }

  /// Updates an existing appointment document in Firestore.
  /// Merges the updated fields with the existing document.
  Future<void> updateAppointment(Appointment appointment) async {
    try {
      await _collection.doc(appointment.id).update(appointment.toMap());
    } catch (e) {
      print('FirestoreService.updateAppointment error: $e');
      rethrow;
    }
  }

  /// Deletes an appointment document from Firestore by its ID.
  Future<void> deleteAppointment(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      print('FirestoreService.deleteAppointment error: $e');
      rethrow;
    }
  }
}
