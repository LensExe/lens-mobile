import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/filter_criteria.dart';
import '../models/photographer_model.dart';
import '../repositories/photographer_repository.dart';
import '../repositories/discovery_repository_provider.dart';

class DiscoveryState {
  final bool isLoading;
  final List<PhotographerModel> photographers;
  final FilterCriteria criteria;
  final SortOption sortOption;
  final int currentPage;
  final bool hasNextPage;
  final int totalCount;
  final String? errorMessage;

  DiscoveryState({
    this.isLoading = true,
    this.photographers = const [],
    required this.criteria,
    this.sortOption = SortOption.featured,
    this.currentPage = 1,
    this.hasNextPage = false,
    this.totalCount = 0,
    this.errorMessage,
  });

  DiscoveryState copyWith({
    bool? isLoading,
    List<PhotographerModel>? photographers,
    FilterCriteria? criteria,
    SortOption? sortOption,
    int? currentPage,
    bool? hasNextPage,
    int? totalCount,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DiscoveryState(
      isLoading: isLoading ?? this.isLoading,
      photographers: photographers ?? this.photographers,
      criteria: criteria ?? this.criteria,
      sortOption: sortOption ?? this.sortOption,
      currentPage: currentPage ?? this.currentPage,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      totalCount: totalCount ?? this.totalCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  int get activeFilterCount {
    int count = 0;
    if (criteria.city != null && criteria.city != 'Tất cả') count++;
    if (criteria.minPrice != null || criteria.maxPrice != null) count++;
    if (criteria.availableDate != null) count++;
    if (criteria.minRating != null) count++;
    if (criteria.experience != null) count++;
    if (criteria.styles.isNotEmpty) count++;
    return count;
  }
}

class DiscoveryController extends Notifier<DiscoveryState> {
  int _requestNumber = 0;
  @override
  DiscoveryState build() {
    // Initial state
    final initialState = DiscoveryState(criteria: FilterCriteria());
    // Fetch initial data right away, using Future.microtask to not block build
    Future.microtask(() => _fetchCurrentPage());
    return initialState;
  }

  PhotographerRepository get _repository =>
      ref.read(discoveryRepositoryProvider);

  Future<void> _fetchCurrentPage() async {
    final request = ++_requestNumber;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final allResults = await _repository.getPhotographers(
        criteria: state.criteria,
        sort: state.sortOption,
      );

      if (request != _requestNumber) return;
      final start = (state.currentPage - 1) * 9;
      state = state.copyWith(
        isLoading: false,
        photographers: allResults.skip(start).take(9).toList(),
        totalCount: allResults.length,
        hasNextPage: start + 9 < allResults.length,
      );
    } catch (e) {
      if (request != _requestNumber) return;
      state = state.copyWith(
        isLoading: false,
        photographers: const [],
        errorMessage:
            'Không thể tải danh sách nhiếp ảnh gia. Vui lòng thử lại.',
      );
    }
  }

  void goToPage(int page) {
    if (page < 1 ||
        (state.totalCount > 0 && (page - 1) * 9 >= state.totalCount)) {
      return;
    }
    state = state.copyWith(currentPage: page);
    _fetchCurrentPage();
  }

  void next() {
    if (state.hasNextPage) {
      goToPage(state.currentPage + 1);
    }
  }

  void previous() {
    if (state.currentPage > 1) {
      goToPage(state.currentPage - 1);
    }
  }

  void updateFilters(FilterCriteria newCriteria) {
    state = state.copyWith(criteria: newCriteria, currentPage: 1);
    _fetchCurrentPage();
  }

  void clearFilters() {
    state = state.copyWith(criteria: FilterCriteria(), currentPage: 1);
    _fetchCurrentPage();
  }

  void updateSort(SortOption sortOption) {
    state = state.copyWith(sortOption: sortOption, currentPage: 1);
    _fetchCurrentPage();
  }

  void toggleStyle(String style) {
    final currentStyles = List<String>.from(state.criteria.styles);
    if (currentStyles.contains(style)) {
      currentStyles.remove(style);
    } else {
      currentStyles.add(style);
    }
    updateFilters(state.criteria.copyWith(styles: currentStyles));
  }

  void search(String query) {
    updateFilters(state.criteria.copyWith(searchQuery: query));
  }

  void applyQuery(Uri uri) {
    final query = uri.queryParameters;
    final experience = Experience.values.where(
      (value) => value.name == query['exp'],
    );
    final sort = SortOption.values.where(
      (value) => value.name == query['sort'],
    );
    final criteria = FilterCriteria(
      searchQuery: query['q'],
      city: query['city'],
      minPrice: double.tryParse(query['priceMin'] ?? ''),
      maxPrice: double.tryParse(query['priceMax'] ?? ''),
      availableDate: DateTime.tryParse(query['date'] ?? ''),
      minRating: double.tryParse(query['rating'] ?? ''),
      experience: experience.isEmpty ? null : experience.first,
      styles:
          query['styles']
              ?.split(',')
              .where((value) => value.isNotEmpty)
              .toList() ??
          [],
    );
    state = state.copyWith(
      criteria: criteria,
      sortOption: sort.isEmpty ? SortOption.featured : sort.first,
      currentPage: int.tryParse(query['page'] ?? '') ?? 1,
    );
    _fetchCurrentPage();
  }

  void retry() => _fetchCurrentPage();
}

final discoveryControllerProvider =
    NotifierProvider<DiscoveryController, DiscoveryState>(() {
      return DiscoveryController();
    });
