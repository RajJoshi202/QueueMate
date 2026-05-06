import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/appointment_model.dart';
import '../providers/appointment_provider.dart';
import '../providers/queue_provider.dart';
import '../widgets/status_badge.dart';

/// AdminDashboardScreen provides admin controls for queue management.
/// Protected by a PIN gate. Shows today's stats and allows status updates.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _isAuthenticated = false;
  final _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isAuthenticated) _showPinDialog();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  /// Shows PIN entry dialog for admin authentication.
  void _showPinDialog() {
    _pinController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: QueueMateTheme.cardBorderRadius),
        title: Row(children: [
          const Icon(Icons.admin_panel_settings, color: QueueMateTheme.primary),
          const SizedBox(width: 8),
          Text('Admin Access', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Enter the admin PIN to continue', style: GoogleFonts.inter(color: Colors.grey[600])),
          const SizedBox(height: 16),
          TextFormField(
            controller: _pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(hintText: 'Enter PIN', prefixIcon: Icon(Icons.lock_outline)),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (_pinController.text == adminPin) {
                setState(() => _isAuthenticated = true);
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Incorrect PIN'),
                  backgroundColor: QueueMateTheme.error,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  /// Shows reschedule dialog for an appointment.
  Future<void> _reschedule(Appointment a) async {
    DateTime? newDate;
    String? newSlot;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: QueueMateTheme.cardBorderRadius),
          title: Text('Reschedule ${a.id}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(newDate != null ? formatDate(newDate!) : 'Select Date'),
              onTap: () async {
                final d = await showDatePicker(context: ctx, initialDate: DateTime.now(),
                  firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)));
                if (d != null) setDialogState(() { newDate = d; newSlot = null; });
              },
            ),
            if (newDate != null)
              DropdownButtonFormField<String>(
                value: newSlot,
                decoration: const InputDecoration(hintText: 'Select Time'),
                items: timeSlots.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setDialogState(() => newSlot = v),
              ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: (newDate != null && newSlot != null) ? () async {
                final t = parseTimeSlot(newSlot!);
                final dt = DateTime(newDate!.year, newDate!.month, newDate!.day, t['hour']!, t['minute']!);
                try {
                  await ref.read(appointmentNotifierProvider.notifier).rescheduleAppointment(a.id, dt);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Appointment rescheduled'), behavior: SnackBarBehavior.floating));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(e.toString().replaceFirst('Exception: ', '')),
                    backgroundColor: QueueMateTheme.error, behavior: SnackBarBehavior.floating));
                }
              } : null,
              child: const Text('Reschedule'),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Dashboard')),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Admin Access Required', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[500])),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showPinDialog,
            icon: const Icon(Icons.login),
            label: const Text('Enter PIN'),
          ),
        ])),
      );
    }

    final appointments = ref.watch(appointmentsProvider);
    final now = DateTime.now();
    final today = appointments.where((a) =>
      a.dateTime.year == now.year && a.dateTime.month == now.month && a.dateTime.day == now.day).toList()
      ..sort((a, b) => a.queuePosition.compareTo(b.queuePosition));

    final inQueue = today.where((a) => a.status == 'Scheduled' || a.status == 'In Progress').length;
    final completed = today.where((a) => a.status == 'Completed').length;
    final cancelled = today.where((a) => a.status == 'Cancelled').length;

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard'), actions: [
        IconButton(icon: const Icon(Icons.logout), onPressed: () => setState(() => _isAuthenticated = false)),
      ]),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Stats row
        Row(children: [
          _statCard('Total', '${today.length}', QueueMateTheme.primary),
          _statCard('In Queue', '$inQueue', QueueMateTheme.scheduled),
          _statCard('Done', '$completed', QueueMateTheme.completed),
          _statCard('Cancelled', '$cancelled', QueueMateTheme.cancelled),
        ]),
        const SizedBox(height: 16),
        // Move Queue Forward
        SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(
          onPressed: () async {
            await ref.read(queueNotifierProvider.notifier).moveQueueForward();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Queue moved forward'), behavior: SnackBarBehavior.floating));
          },
          icon: const Icon(Icons.skip_next),
          label: const Text('Move Queue Forward'),
          style: ElevatedButton.styleFrom(backgroundColor: QueueMateTheme.secondary, foregroundColor: Colors.black87),
        )),
        const SizedBox(height: 20),
        Text("Today's Appointments", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (today.isEmpty)
          Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text('No appointments today', style: GoogleFonts.inter(color: Colors.grey[500])),
          ])))
        else
          ...today.map((a) => _adminCard(a)),
      ])),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(child: Card(
      shape: RoundedRectangleBorder(borderRadius: QueueMateTheme.cardBorderRadius),
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(children: [
          Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600])),
        ]))));
  }

  Widget _adminCard(Appointment a) {
    final notifier = ref.read(appointmentNotifierProvider.notifier);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: QueueMateTheme.cardBorderRadius),
      child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: QueueMateTheme.primary, borderRadius: BorderRadius.circular(20)),
            child: Text('#${a.queuePosition}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
            Text('${a.serviceType} • ${formatTime(a.dateTime)}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
          ])),
          StatusBadge(status: a.status),
        ]),
        const SizedBox(height: 10),
        const Divider(height: 1),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 4, children: [
          if (a.status == 'Scheduled')
            _actionBtn('Start', Icons.play_arrow, QueueMateTheme.inProgress, () => notifier.updateStatus(a.id, 'In Progress')),
          if (a.status == 'In Progress')
            _actionBtn('Complete', Icons.check, QueueMateTheme.completed, () => notifier.updateStatus(a.id, 'Completed')),
          if (a.status != 'Cancelled' && a.status != 'Completed')
            _actionBtn('Cancel', Icons.cancel, QueueMateTheme.cancelled, () => notifier.cancelAppointment(a.id)),
          if (a.status == 'Scheduled')
            _actionBtn('Reschedule', Icons.schedule, QueueMateTheme.scheduled, () => _reschedule(a)),
        ]),
      ])),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(.4)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
