import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

/// QueueIndicator displays a circular progress indicator showing the
/// user's position relative to the total queue size.
/// Color changes based on proximity: green if next, orange if close, blue otherwise.
class QueueIndicator extends StatelessWidget {
  final int position;
  final int total;

  const QueueIndicator({
    super.key,
    required this.position,
    required this.total,
  });

  /// Determines the indicator color based on queue proximity.
  Color _getColor() {
    if (position <= 1) return QueueMateTheme.completed; // Green — you're next
    if (position <= 3) return QueueMateTheme.inProgress; // Orange — close
    return QueueMateTheme.scheduled; // Blue — waiting
  }

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? (total - position + 1) / total : 0.0;
    final color = _getColor();

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular progress background
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: 8,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          // Center text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Position',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '$position',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                'of $total',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
