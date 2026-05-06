import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/appointment_model.dart';
import '../providers/appointment_provider.dart';
import '../providers/queue_provider.dart';
import '../widgets/offline_banner.dart';
import '../widgets/queue_indicator.dart';
import '../widgets/status_badge.dart';

/// QueueStatusScreen displays live queue status with auto-refresh.
class QueueStatusScreen extends ConsumerStatefulWidget {
  const QueueStatusScreen({super.key});
  @override
  ConsumerState<QueueStatusScreen> createState() => _QueueStatusScreenState();
}

class _QueueStatusScreenState extends ConsumerState<QueueStatusScreen> {
  Timer? _refreshTimer;
  final _idController = TextEditingController();
  Appointment? _tracked;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) ref.read(appointmentNotifierProvider.notifier).refreshFromFirestore();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _idController.dispose();
    super.dispose();
  }

  void _lookup() {
    final id = _idController.text.trim().toUpperCase();
    if (id.isEmpty) return;
    final found = ref.read(appointmentsProvider).where((a) => a.id == id).toList();
    if (found.isNotEmpty) {
      setState(() => _tracked = found.first);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No appointment found with ID: $id'),
        backgroundColor: QueueMateTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final qs = ref.watch(queueNotifierProvider);
    final appts = ref.watch(appointmentsProvider);
    if (_tracked != null) {
      final u = appts.where((a) => a.id == _tracked!.id).toList();
      if (u.isNotEmpty) _tracked = u.first;
    }
    final ct = qs.currentToken;
    final tq = qs.todayQueue;
    final total = tq.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Queue Status'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: () =>
          ref.read(appointmentNotifierProvider.notifier).refreshFromFirestore()),
      ]),
      body: Column(children: [
        const OfflineBanner(),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
          // Now Serving card
          Card(elevation: 4, shape: RoundedRectangleBorder(borderRadius: QueueMateTheme.cardBorderRadius),
            child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [QueueMateTheme.primary, QueueMateTheme.primaryLight]),
                borderRadius: QueueMateTheme.cardBorderRadius),
              child: Column(children: [
                Text('NOW SERVING', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70, letterSpacing: 2)),
                const SizedBox(height: 8),
                Text(ct > 0 ? '#$ct' : '--', style: GoogleFonts.poppins(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('$total people in queue', style: GoogleFonts.inter(fontSize: 13, color: Colors.white60)),
              ]))),
          const SizedBox(height: 24),
          if (_tracked != null) _buildTracked(_tracked!, ct, total)
          else _buildLookup(),
        ])))
      ]),
    );
  }

  Widget _buildLookup() {
    return Card(shape: RoundedRectangleBorder(borderRadius: QueueMateTheme.cardBorderRadius),
      child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        Icon(Icons.search, size: 40, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Text('Track Your Appointment', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Enter your Appointment ID to check status', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: TextFormField(controller: _idController, decoration: const InputDecoration(hintText: 'e.g., APT-A1B2C3', prefixIcon: Icon(Icons.confirmation_number)), textCapitalization: TextCapitalization.characters)),
          const SizedBox(width: 12),
          ElevatedButton(onPressed: _lookup, child: const Text('Look Up')),
        ]),
      ])));
  }

  Widget _buildTracked(Appointment a, int ct, int total) {
    final wait = estimatedWaitMinutes(a.queuePosition, ct);
    final isNext = ct > 0 && a.queuePosition == ct + 1;
    final isActive = a.status == 'Scheduled' || a.status == 'In Progress';
    return Column(children: [
      if (isNext && isActive) ...[
        TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: 1), duration: const Duration(milliseconds: 800),
          builder: (_, v, c) => Opacity(opacity: v, child: Transform.scale(scale: .9 + .1 * v, child: c)),
          child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFC107), Color(0xFFFFD54F)]),
              borderRadius: QueueMateTheme.cardBorderRadius, boxShadow: [BoxShadow(color: const Color(0xFFFFC107).withOpacity(.3), blurRadius: 12, offset: const Offset(0, 4))]),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.celebration, color: Colors.black87), const SizedBox(width: 8),
              Text("You're Next!", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            ]))),
        const SizedBox(height: 16),
      ],
      Card(shape: RoundedRectangleBorder(borderRadius: QueueMateTheme.cardBorderRadius),
        child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          QueueIndicator(position: a.queuePosition, total: total),
          const SizedBox(height: 20),
          _row(Icons.badge_outlined, 'ID', a.id),
          _row(Icons.person_outline, 'Name', a.name),
          _row(Icons.medical_services_outlined, 'Service', a.serviceType),
          _row(Icons.calendar_today_outlined, 'Date/Time', formatDateTime(a.dateTime)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Status: ', style: GoogleFonts.inter(color: Colors.grey[600])),
            StatusBadge(status: a.status),
          ]),
          const SizedBox(height: 16),
          if (isActive && wait > 0) Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: QueueMateTheme.scheduled.withOpacity(.08), borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.timer_outlined, color: QueueMateTheme.scheduled, size: 20), const SizedBox(width: 8),
              Text('Estimated wait: ~$wait min', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: QueueMateTheme.scheduled)),
            ])),
          if (isActive && total > 0) ...[
            const SizedBox(height: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Queue Progress', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 6),
              ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: (total - a.queuePosition + 1) / total, minHeight: 8, backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(QueueMateTheme.statusColor(a.status)))),
            ]),
          ],
          const SizedBox(height: 12),
          TextButton.icon(onPressed: () { setState(() => _tracked = null); _idController.clear(); },
            icon: const Icon(Icons.close, size: 18), label: const Text('Track Another')),
        ]))),
    ]);
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.grey[500]), const SizedBox(width: 10),
        Text('$label: ', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
        Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500), textAlign: TextAlign.end)),
      ]));
  }
}
