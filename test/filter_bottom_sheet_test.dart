import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lens_app/features/customer/discovery/models/filter_criteria.dart';
import 'package:lens_app/features/customer/discovery/widgets/filter_bottom_sheet.dart';

void main() {
  testWidgets('applies only Backend-supported location and rating filters', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    FilterCriteria? applied;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const ValueKey('open-filter-sheet'),
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => FilterBottomSheet(
                      initialCriteria: FilterCriteria(),
                      onApply: (criteria) => applied = criteria,
                    ),
                  );
                },
                child: const Text('Open filters'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('open-filter-sheet')));
    await tester.pumpAndSettle();
    expect(find.text('Bộ lọc tìm kiếm'), findsOneWidget);
    await tester.tap(find.text('Hà Nội'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Áp dụng'));
    await tester.pumpAndSettle();

    expect(applied?.city, 'Hà Nội');
    expect(applied?.minRating, isNull);
  });
}
