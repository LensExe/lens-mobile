import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/filter_criteria.dart';
import '../models/photographer_model.dart';
import '../repositories/mock_photographer_repository.dart';
import '../repositories/photographer_repository.dart';

final discoveryRepositoryProvider = Provider<PhotographerRepository>((ref) {
  return MockPhotographerRepository();
});

class DiscoveryState {
  final bool isLoading;
  final List<PhotographerModel> photographers;
  final FilterCriteria criteria;
  final SortOption sortOption;
  final int currentPage;
  final bool hasNextPage;

  DiscoveryState({
    this.isLoading = true,
    this.photographers = const [],
    required this.criteria,
    this.sortOption = SortOption.featured,
    this.currentPage = 1,
    this.hasNextPage = false,
  });

  DiscoveryState copyWith({
    bool? isLoading,
    List<PhotographerModel>? photographers,
    FilterCriteria? criteria,
    SortOption? sortOption,
    int? currentPage,
    bool? hasNextPage,
  }) {
    return DiscoveryState(
      isLoading: isLoading ?? this.isLoading,
      photographers: photographers ?? this.photographers,
      criteria: criteria ?? this.criteria,
      sortOption: sortOption ?? this.sortOption,
      currentPage: currentPage ?? this.currentPage,
      hasNextPage: hasNextPage ?? this.hasNextPage,
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
  @override
  DiscoveryState build() {
    // Initial state
    final initialState = DiscoveryState(criteria: FilterCriteria());
    // Fetch initial data right away, using Future.microtask to not block build
    Future.microtask(() => _fetchCurrentPage());
    return initialState;
  }

  PhotographerRepository get _repository => ref.read(discoveryRepositoryProvider);

  Future<void> _fetchCurrentPage() async {
    state = state.copyWith(isLoading: true);
    try {
      final allResults = await _repository.getPhotographers(
        criteria: state.criteria,
        sort: state.sortOption,
      );
      
      state = state.copyWith(
        isLoading: false,
        photographers: allResults,
        hasNextPage: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void goToPage(int page) {
    if (page < 1) return;
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
}

final discoveryControllerProvider = NotifierProvider<DiscoveryController, DiscoveryState>(() {
  return DiscoveryController();
});
