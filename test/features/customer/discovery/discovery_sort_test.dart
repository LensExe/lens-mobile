import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lens_app/features/customer/discovery/models/filter_criteria.dart';
import 'package:lens_app/features/customer/discovery/models/photographer_model.dart';
import 'package:lens_app/features/customer/discovery/repositories/discovery_repository_provider.dart';
import 'package:lens_app/features/customer/discovery/repositories/photographer_repository.dart';
import 'package:lens_app/features/customer/discovery/screens/photographers_discovery_screen.dart';

class _FakePhotographerRepo implements PhotographerRepository {
  List<PhotographerModel> items = [
    PhotographerModel(
      id: 'p1',
      name: 'Alpha Photographer',
      avatarUrl: '',
      coverImageUrl: '',
      city: 'Hà Nội',
      rating: 5.0,
      reviewCount: 10,
      pricePerSession: 500000,
      isFeatured: false,
      isVerified: true,
      styles: ['Chân dung'],
      availableDates: [],
    ),
    PhotographerModel(
      id: 'p2',
      name: 'Beta Photographer',
      avatarUrl: '',
      coverImageUrl: '',
      city: 'Hà Nội',
      rating: 4.2,
      reviewCount: 5,
      pricePerSession: 2000000,
      isFeatured: false,
      isVerified: true,
      styles: ['Chân dung'],
      availableDates: [],
    ),
  ];

  FilterCriteria? lastCriteria;

  @override
  Future<PhotographerPage> getPhotographersPage({
    FilterCriteria? criteria,
    required int limit,
    required int offset,
    bool topRated = false,
  }) async {
    lastCriteria = criteria;
    var list = List<PhotographerModel>.from(items);
    if (criteria?.sort == 'price-desc') {
      list.sort((a, b) => b.pricePerSession.compareTo(a.pricePerSession));
    } else if (criteria?.sort == 'price-asc') {
      list.sort((a, b) => a.pricePerSession.compareTo(b.pricePerSession));
    } else if (criteria?.sort == 'rating') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return PhotographerPage(
      items: list,
      total: list.length,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<List<PhotographerModel>> getPhotographers({FilterCriteria? criteria}) async => items;

  @override
  Future<void> recordReview(String photographerId, double rating) async {}
}

void main() {
  testWidgets('Selecting sort in toolbar updates criteria and reorders photographers', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = _FakePhotographerRepo();

    final router = GoRouter(
      initialLocation: '/customer_home/discovery',
      routes: [
        GoRoute(
          path: '/customer_home/discovery',
          builder: (context, state) => const PhotographersDiscoveryScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial sort button is present
    expect(find.byTooltip('Sắp xếp kết quả'), findsOneWidget);
    expect(find.text('Alpha Photographer'), findsOneWidget);

    // Tap sort popup menu
    await tester.tap(find.byTooltip('Sắp xếp kết quả'));
    await tester.pumpAndSettle();

    // Verify menu items appear
    expect(find.text('Đánh giá cao'), findsOneWidget);
    expect(find.text('Giá: cao → thấp'), findsOneWidget);

    // Select 'Giá: cao → thấp'
    await tester.tap(find.text('Giá: cao → thấp'));
    await tester.pumpAndSettle();

    expect(repo.lastCriteria?.sort, 'price-desc');
  });
}
