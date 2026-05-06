import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/appointment_model.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import 'status_badge.dart';

/// AppointmentCard widget displays a single appointment's details
/// in a styled Material card with rounded corners and subtle shadow.
/// Supports an optional trailing action widget for admin controls.
class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final Widget? trailing;
  final VoidCallback? onTap;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: QueueMateTheme.cardBorderRadius,
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: QueueMateTheme.cardBorderRadius,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Top Row: ID and Status Badge ────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Appointment ID chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: QueueMateTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      appointment.id,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: QueueMateTheme.primary,
                      ),
                    ),
                  ),
                  StatusBadge(status: appointment.status),
                ],
              ),
              const SizedBox(height: 12),

              // ─── Name ────────────────────────────────────
              Text(
                appointment.name,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),

              // ─── Service Type ────────────────────────────
              Row(
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    appointment.serviceType,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // ─── Date & Time ─────────────────────────────
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formatDateTime(appointment.dateTime),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // ─── Queue Position ──────────────────────────
              Row(
                children: [
                  Icon(
                    Icons.confirmation_number_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Queue #${appointment.queuePosition}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  // Sync indicator
                  if (!appointment.synced) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.cloud_off,
                      size: 14,
                      color: Colors.orange[700],
                    ),
                  ],
                ],
              ),

              // ─── Trailing Actions ────────────────────────
              if (trailing != null) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
