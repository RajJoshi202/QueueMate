import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../providers/filter_provider.dart';
import '../widgets/appointment_card.dart';

/// SearchFilterScreen provides advanced search and filtering for appointments.
/// Supports text search, date filter, status chips, and service type chips.
/// All filters combine with AND logic.
class SearchFilterScreen extends ConsumerStatefulWidget {
  const SearchFilterScreen({super.key});
  @override
  ConsumerState<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends ConsumerState<SearchFilterScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(filterNotifierProvider).searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(filterNotifierProvider);
    final filtered = ref.watch(filteredAppointmentsProvider);
    final notifier = ref.read(filterNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search & Filter'),
        actions: [
          if (filter.hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear All Filters',
              onPressed: () {
                notifier.clearAll();
                _searchController.clear();
              },
            ),
        ],
      ),
      body: Column(children: [
        // Search & Filter controls
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Search Bar
            TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or appointment ID...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.close), onPressed: () {
                        _searchController.clear();
                        notifier.setSearch('');
                      })
                    : null,
              ),
              onChanged: (v) => notifier.setSearch(v),
            ),
            const SizedBox(height: 16),

            // Date Filter
            Row(children: [
              Text('Date: ', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
              TextButton.icon(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: filter.selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  notifier.setDate(d);
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(filter.selectedDate != null ? formatDate(filter.selectedDate!) : 'Any Date'),
              ),
              if (filter.selectedDate != null)
                IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => notifier.setDate(null)),
            ]),
            const SizedBox(height: 8),

            // Status Filter
            Text('Status:', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 4, children: [
              for (final s in ['Scheduled', 'In Progress', 'Completed', 'Cancelled'])
                FilterChip(
                  label: Text(s),
                  selected: filter.selectedStatuses.contains(s),
                  selectedColor: QueueMateTheme.statusColor(s).withOpacity(.2),
                  checkmarkColor: QueueMateTheme.statusColor(s),
                  onSelected: (sel) {
                    final list = List<String>.from(filter.selectedStatuses);
                    sel ? list.add(s) : list.remove(s);
                    notifier.setStatuses(list);
                  },
                ),
            ]),
            const SizedBox(height: 12),

            // Service Type Filter
            Text('Service Type:', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 4, children: [
              for (final t in serviceTypes)
                FilterChip(
                  label: Text(t),
                  selected: filter.selectedServiceTypes.contains(t),
                  selectedColor: QueueMateTheme.primary.withOpacity(.15),
                  checkmarkColor: QueueMateTheme.primary,
                  onSelected: (sel) {
                    final list = List<String>.from(filter.selectedServiceTypes);
                    sel ? list.add(t) : list.remove(t);
                    notifier.setServiceTypes(list);
                  },
                ),
            ]),
          ]),
        ),
        // Results
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Text('Showing ${filtered.length} results',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          ]),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('No appointments found', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[500])),
                  const SizedBox(height: 4),
                  Text('Try adjusting your filters', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400])),
                ]))
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => AppointmentCard(appointment: filtered[i]),
                ),
        ),
      ]),
    );
  }
}
