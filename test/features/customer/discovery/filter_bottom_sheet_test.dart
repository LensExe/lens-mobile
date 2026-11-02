import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lens_app/features/customer/discovery/models/filter_criteria.dart';
import 'package:lens_app/features/customer/discovery/widgets/filter_bottom_sheet.dart';

void main() {
  testWidgets('applies multi-style, city, rating, and experience filters', (
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
    await _tapVisible(tester, find.text('Chân dung').first);
    await _tapVisible(tester, find.text('Cưới').first);
    await _tapVisible(tester, find.text('Hà Nội'));
    await _tapVisible(tester, find.text('4.8★ trở lên'));
    await _tapVisible(tester, find.text('Trên 5 năm'));
    await _tapVisible(tester, find.text('Áp dụng'));
    await tester.pumpAndSettle();

    expect(applied?.city, 'Hà Nội');
    expect(applied?.styles, ['Chân dung', 'Cưới']);
    expect(applied?.minRating, 4.8);
    expect(applied?.experienceBucket, '5+');
  });
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
