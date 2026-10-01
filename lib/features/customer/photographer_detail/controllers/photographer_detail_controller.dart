import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/photographer_detail_model.dart';
import '../repositories/photographer_detail_repository.dart';
import '../repositories/photographer_detail_repository_provider.dart';

class PhotographerDetailState {
  final bool isLoading;
  final PhotographerProfile? profile;
  final int selectedTabIndex; // 0: Portfolio, 1: About, 2: Reviews
  final String selectedPortfolioStyle;
  final ProfilePackage? selectedPackage;
  final bool isBookmarked;
  final String? errorMessage;

  const PhotographerDetailState({
    this.isLoading = true,
    this.profile,
    this.selectedTabIndex = 0,
    this.selectedPortfolioStyle = 'Tất cả',
    this.selectedPackage,
    this.isBookmarked = false,
    this.errorMessage,
  });

  PhotographerDetailState copyWith({
    bool? isLoading,
    PhotographerProfile? profile,
    int? selectedTabIndex,
    String? selectedPortfolioStyle,
    ProfilePackage? selectedPackage,
    bool? isBookmarked,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PhotographerDetailState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      selectedPortfolioStyle:
          selectedPortfolioStyle ?? this.selectedPortfolioStyle,
      selectedPackage: selectedPackage ?? this.selectedPackage,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  List<PortfolioItem> get filteredPortfolio {
    if (profile == null) return const [];
    if (selectedPortfolioStyle == 'Tất cả') return profile!.portfolio;
    return profile!.portfolio
        .where((item) => item.style == selectedPortfolioStyle)
        .toList();
  }
}

class PhotographerDetailController extends Notifier<PhotographerDetailState> {
  @override
  PhotographerDetailState build() {
    return const PhotographerDetailState();
  }

  PhotographerDetailRepository get _repo =>
      ref.read(photographerDetailRepositoryProvider);

  Future<void> loadProfile(String id) async {
    state = const PhotographerDetailState(isLoading: true);
    try {
      final profile = await _repo.getPhotographerProfile(id);
      final defaultPkg = profile.packages.isNotEmpty
          ? profile.packages.firstWhere(
              (p) => p.isMostSelected,
              orElse: () => profile.packages.first,
            )
          : null;
      state = state.copyWith(
        isLoading: false,
        profile: profile,
        selectedPackage: defaultPkg,
        selectedTabIndex: 0,
        selectedPortfolioStyle: 'Tất cả',
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải hồ sơ nhiếp ảnh gia.',
      );
    }
  }

  void selectTab(int index) {
    state = state.copyWith(selectedTabIndex: index);
  }

  void selectPortfolioStyle(String style) {
    state = state.copyWith(selectedPortfolioStyle: style);
  }

  void selectPackage(ProfilePackage pkg) {
    state = state.copyWith(selectedPackage: pkg);
  }

  void toggleBookmark() {
    state = state.copyWith(isBookmarked: !state.isBookmarked);
  }
}

final photographerDetailControllerProvider =
    NotifierProvider<PhotographerDetailController, PhotographerDetailState>(() {
      return PhotographerDetailController();
    });
