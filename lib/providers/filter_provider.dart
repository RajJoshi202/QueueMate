import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/appointment_model.dart';
import 'appointment_provider.dart';

/// FilterState holds all active filter criteria for appointment search.
/// All filters combine with AND logic when applied.
class FilterState {
  final String searchQuery;
  final DateTime? selectedDate;
  final List<String> selectedStatuses;
  final List<String> selectedServiceTypes;

  const FilterState({
    this.searchQuery = '',
    this.selectedDate,
    this.selectedStatuses = const [],
    this.selectedServiceTypes = const [],
  });

  /// Creates a copy of this state with optional overrides.
  FilterState copyWith({
    String? searchQuery,
    DateTime? selectedDate,
    bool clearDate = false,
    List<String>? selectedStatuses,
    List<String>? selectedServiceTypes,
  }) {
    return FilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedDate: clearDate ? null : (selectedDate ?? this.selectedDate),
      selectedStatuses: selectedStatuses ?? this.selectedStatuses,
      selectedServiceTypes: selectedServiceTypes ?? this.selectedServiceTypes,
    );
  }

  /// Returns true if any filter is active.
  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      selectedDate != null ||
      selectedStatuses.isNotEmpty ||
      selectedServiceTypes.isNotEmpty;
}

/// FilterNotifier manages the filter state for appointment searching.
/// Provides methods to set individual filters and clear all at once.
class FilterNotifier extends StateNotifier<FilterState> {
  FilterNotifier() : super(const FilterState());

  /// Sets the search query for name/ID filtering.
  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Sets the date filter to show appointments on a specific day.
  void setDate(DateTime? date) {
    if (date == null) {
      state = state.copyWith(clearDate: true);
    } else {
      state = state.copyWith(selectedDate: date);
    }
  }

  /// Sets the status filter to show only selected statuses.
  void setStatuses(List<String> statuses) {
    state = state.copyWith(selectedStatuses: statuses);
  }

  /// Sets the service type filter to show only selected types.
  void setServiceTypes(List<String> types) {
    state = state.copyWith(selectedServiceTypes: types);
  }

  /// Clears all active filters and resets to defaults.
  void clearAll() {
    state = const FilterState();
  }
}

// ─── Riverpod Providers ──────────────────────────────────────────

/// Provides the FilterNotifier for managing filter state.
final filterNotifierProvider =
    StateNotifierProvider<FilterNotifier, FilterState>((ref) {
  return FilterNotifier();
});

/// Derived provider that applies all active filters to the appointment list.
/// Combines search query, date, status, and service type filters with AND logic.
final filteredAppointmentsProvider = Provider<List<Appointment>>((ref) {
  final appointments = ref.watch(appointmentsProvider);
  final filter = ref.watch(filterNotifierProvider);

  return appointments.where((a) {
    // Search filter: matches name or appointment ID (case-insensitive)
    if (filter.searchQuery.isNotEmpty) {
      final query = filter.searchQuery.toLowerCase();
      final matchesName = a.name.toLowerCase().contains(query);
      final matchesId = a.id.toLowerCase().contains(query);
      if (!matchesName && !matchesId) return false;
    }

    // Date filter: matches the selected day
    if (filter.selectedDate != null) {
      final sd = filter.selectedDate!;
      if (a.dateTime.year != sd.year ||
          a.dateTime.month != sd.month ||
          a.dateTime.day != sd.day) {
        return false;
      }
    }

    // Status filter: matches any of the selected statuses
    if (filter.selectedStatuses.isNotEmpty) {
      if (!filter.selectedStatuses.contains(a.status)) return false;
    }

    // Service type filter: matches any of the selected types
    if (filter.selectedServiceTypes.isNotEmpty) {
      if (!filter.selectedServiceTypes.contains(a.serviceType)) return false;
    }

    return true;
  }).toList();
});
