import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/appointment_model.dart';
import '../providers/appointment_provider.dart';
import '../widgets/offline_banner.dart';

/// BookingScreen allows users to book a new appointment.
/// Contains a form with name, service type, date, and time slot selection.
/// Validates all inputs and creates the appointment through the provider.
class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedService;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Opens a date picker dialog for selecting the appointment date.
  /// Restricts selection to today and future dates only.
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: QueueMateTheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlot = null; // Reset time when date changes
      });
    }
  }

  /// Checks if a specific time slot is full for the selected date.
  bool _isSlotFull(String slot) {
    if (_selectedDate == null) return false;
    final time = parseTimeSlot(slot);
    final dateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      time['hour']!,
      time['minute']!,
    );
    return isSlotFull(ref.read(appointmentsProvider), dateTime);
  }

  /// Handles form submission and appointment creation.
  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      _showError('Please select a date');
      return;
    }
    if (_selectedTimeSlot == null) {
      _showError('Please select a time slot');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final time = parseTimeSlot(_selectedTimeSlot!);
      final dateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        time['hour']!,
        time['minute']!,
      );

      final appointments = ref.read(appointmentsProvider);
      final queuePos = getQueuePosition(appointments, dateTime);
      final id = generateAppointmentId();

      final appointment = Appointment(
        id: id,
        name: _nameController.text.trim(),
        serviceType: _selectedService!,
        dateTime: dateTime,
        queuePosition: queuePos,
        status: 'Scheduled',
        synced: false,
      );

      await ref
          .read(appointmentNotifierProvider.notifier)
          .addAppointment(appointment);

      if (mounted) {
        _showSuccessDialog(id, queuePos);
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Shows a success dialog with the appointment ID and queue number.
  void _showSuccessDialog(String id, int queuePos) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: QueueMateTheme.cardBorderRadius,
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: QueueMateTheme.completed, size: 28),
            const SizedBox(width: 8),
            Text(
              'Booking Confirmed!',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Appointment ID', id),
            const SizedBox(height: 8),
            _infoRow('Queue Number', '#$queuePos'),
            const SizedBox(height: 8),
            _infoRow('Date', formatDate(_selectedDate!)),
            const SizedBox(height: 8),
            _infoRow('Time', _selectedTimeSlot!),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: QueueMateTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: QueueMateTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Save your Appointment ID to check queue status',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: QueueMateTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  /// Helper widget to display info rows in the success dialog.
  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13)),
        Text(value,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  /// Shows an error SnackBar with the given message.
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: QueueMateTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Resets the form fields to their initial state.
  void _resetForm() {
    _nameController.clear();
    setState(() {
      _selectedService = null;
      _selectedDate = null;
      _selectedTimeSlot = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Header ──────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            QueueMateTheme.primary,
                            QueueMateTheme.primaryLight,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: QueueMateTheme.cardBorderRadius,
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.calendar_month,
                              color: Colors.white, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            'Schedule Your Visit',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fill in the details below to book your appointment',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ─── Full Name ───────────────────────────
                    Text('Full Name',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        )),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your full name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
                          return 'Name should only contain letters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // ─── Service Type ────────────────────────
                    Text('Service Type',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        )),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedService,
                      decoration: const InputDecoration(
                        hintText: 'Select a service',
                        prefixIcon: Icon(Icons.medical_services_outlined),
                      ),
                      items: serviceTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedService = value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a service type';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // ─── Date Picker ─────────────────────────
                    Text('Appointment Date',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        )),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: QueueMateTheme.cardBorderRadius,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                          borderRadius: QueueMateTheme.cardBorderRadius,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                color: Colors.grey[600], size: 20),
                            const SizedBox(width: 12),
                            Text(
                              _selectedDate != null
                                  ? formatDate(_selectedDate!)
                                  : 'Select a date',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: _selectedDate != null
                                    ? Colors.black87
                                    : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ─── Time Slot ───────────────────────────
                    Text('Time Slot',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        )),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedTimeSlot,
                      decoration: const InputDecoration(
                        hintText: 'Select a time slot',
                        prefixIcon: Icon(Icons.access_time_outlined),
                      ),
                      items: timeSlots.map((slot) {
                        final full = _isSlotFull(slot);
                        return DropdownMenuItem<String>(
                          value: slot, // Always use the slot string as value (never null)
                          enabled: !full,
                          child: Text(
                            full ? '$slot (Full)' : slot,
                            style: TextStyle(
                              color: full ? Colors.grey[400] : Colors.black87,
                              fontStyle:
                                  full ? FontStyle.italic : FontStyle.normal,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        // Double-check the slot isn't full before selecting
                        if (_isSlotFull(value)) return;
                        setState(() => _selectedTimeSlot = value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a time slot';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // ─── Submit Button ───────────────────────
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitBooking,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(
                          _isSubmitting ? 'Booking...' : 'Book Appointment',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
