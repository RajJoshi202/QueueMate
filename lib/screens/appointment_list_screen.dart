import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../models/appointment_model.dart';
import '../providers/appointment_provider.dart';
import '../widgets/appointment_card.dart';
import '../widgets/offline_banner.dart';
import 'booking_screen.dart';
import 'search_filter_screen.dart';

/// AppointmentListScreen displays all user appointments in a scrollable list.
/// Supports pull-to-refresh, swipe-to-cancel, and navigation to booking/search.
class AppointmentListScreen extends ConsumerWidget {
  const AppointmentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appointmentNotifierProvider);
    final appointments = List<Appointment>.from(state.appointments)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SearchFilterScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(appointmentNotifierProvider.notifier).refreshFromFirestore(),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : appointments.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: () => ref.read(appointmentNotifierProvider.notifier).refreshFromFirestore(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: appointments.length,
                          itemBuilder: (ctx, i) {
                            final a = appointments[i];
                            if (a.status == 'Scheduled') {
                              return Dismissible(
                                key: ValueKey(a.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: QueueMateTheme.cancelled,
                                    borderRadius: QueueMateTheme.cardBorderRadius,
                                  ),
                                  child: const Icon(Icons.cancel, color: Colors.white, size: 28),
                                ),
                                confirmDismiss: (_) => _confirmCancel(context),
                                onDismissed: (_) => ref.read(appointmentNotifierProvider.notifier).cancelAppointment(a.id),
                                child: AppointmentCard(appointment: a),
                              );
                            }
                            return AppointmentCard(appointment: a);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const BookingScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Book'),
      ),
    );
  }

  /// Shows a confirmation dialog before cancelling an appointment.
  Future<bool> _confirmCancel(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: QueueMateTheme.cardBorderRadius),
            title: Text('Cancel Appointment?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            content: const Text('Are you sure you want to cancel this appointment? This action cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No, Keep It')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: QueueMateTheme.cancelled),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Yes, Cancel'),
              ),
            ],
          ),
        ) ?? false;
  }

  /// Empty state widget when no appointments exist.
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No Appointments Yet', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[500])),
          const SizedBox(height: 8),
          Text('Book your first appointment to get started', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400])),
        ],
      ),
    );
  }
}
