import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lens_app/core/router/app_router.dart';
import 'package:lens_app/core/widgets/primary_button.dart';
import 'package:lens_app/core/utils/vietnamese_text.dart';
import 'package:lens_app/data/mock_database.dart';
import 'package:lens_app/data/repositories/mock_auth_repository.dart';
import 'package:lens_app/data/repositories/mock_customer_reviews_repository.dart';
import 'package:lens_app/data/repositories/mock_customer_wallet_repository.dart';
import 'package:lens_app/data/repositories/mock_customer_messages_repository.dart';
import 'package:lens_app/domain/models/models.dart' show Message, User;
import 'package:lens_app/providers/data_providers.dart';
import 'package:lens_app/features/customer/bookings/models/booking_model.dart';
import 'package:lens_app/features/customer/booking_flow/controllers/booking_wizard_controller.dart';
import 'package:lens_app/features/customer/bookings/repositories/mock_booking_repository.dart';
import 'package:lens_app/features/customer/bookings/widgets/cancel_booking_dialog.dart';
import 'package:lens_app/features/customer/discovery/models/filter_criteria.dart';
import 'package:lens_app/features/customer/discovery/repositories/mock_photographer_repository.dart';

String _dateAfter(int days) {
  final date = DateTime.now().add(Duration(days: days));
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

Booking _booking(String id, {String? date, String timeSlot = '08:00 - 09:00'}) {
  return Booking(
    id: id,
    clientId: 'test-client',
    clientName: 'Khách thử nghiệm',
    photographerId: 'test-photographer',
    photographerName: 'Thợ thử nghiệm',
    style: 'Chân dung',
    date: date ?? _dateAfter(14),
    timeSlot: timeSlot,
    location: 'Hà Nội',
    price: 1000000,
    status: BookingStatus.awaiting_deposit,
    packageId: 'basic',
    packageSnapshot: const PackageTerms(
      name: 'Gói cơ bản',
      photoCount: 15,
      durationHours: 1,
      deliveryDays: 5,
    ),
    depositAmount: 300000,
    depositDeadline: DateTime.now()
        .add(const Duration(minutes: 30))
        .toIso8601String(),
  );
}

void main() {
  test(
    'mock authentication checks credentials and saves password changes',
    () async {
      MockDatabase.currentUser = null;
      final repository = MockAuthRepository();
      final email =
          'customer-${DateTime.now().microsecondsSinceEpoch}@lens.test';
      final user = await repository.signup(
        name: 'Khách mới',
        email: email,
        password: 'password123',
        role: 'client',
      );
      expect(user.email, email);
      await repository.logout();
      expect(MockDatabase.currentUser, isNull);
      await expectLater(
        repository.login(email: email, password: 'wrong-password'),
        throwsA(isA<AuthException>()),
      );
      await repository.login(email: email, password: 'password123');
      await repository.changePassword(
        currentPassword: 'password123',
        newPassword: 'new-password123',
      );
      await repository.logout();
      await expectLater(
        repository.login(email: email, password: 'password123'),
        throwsA(isA<AuthException>()),
      );
      expect(
        (await repository.login(email: email, password: 'new-password123')).id,
        user.id,
      );
      await repository.logout();
    },
  );

  test(
    'booking repository enforces checkout states and slot conflicts',
    () async {
      final repository = MockBookingRepository();
      final booking = _booking('test-${DateTime.now().microsecondsSinceEpoch}');
      await repository.createBooking(booking);
      await expectLater(
        repository.createBooking(
          _booking('${booking.id}-overlap', timeSlot: '08:30 - 09:30'),
        ),
        throwsStateError,
      );
      await expectLater(
        repository.payRemaining(booking.id, 0),
        throwsStateError,
      );
      await repository.updateBookingStatus(booking.id, BookingStatus.pending);
      expect(
        (await repository.getBookingById(booking.id))!.depositPaidAt,
        isNotNull,
      );
      await repository.updateBookingStatus(booking.id, BookingStatus.confirmed);
      await expectLater(
        repository.payRemaining(booking.id, 300000),
        throwsStateError,
      );
      await repository.payRemaining(booking.id, 100000);
      final paid = (await repository.getBookingById(booking.id))!;
      expect(paid.status, BookingStatus.held);
      expect(paid.coinsRedeemed, 100000);
      await expectLater(
        repository.updateBookingStatus(booking.id, BookingStatus.released),
        throwsStateError,
      );
    },
  );

  test('cancellation returns cash and redeemed coins using calendar days', () {
    final base = _booking('policy')
        .copyWith(status: BookingStatus.held, coinsRedeemed: 100000);
    final early = CancelBookingTerms.calculate(base);
    expect(early.refundAmount, 900000);
    expect(early.coinsBack, 100000);
    expect(early.penaltyAmount, 0);

    final late = CancelBookingTerms.calculate(
      base.copyWith(date: _dateAfter(3)),
    );
    expect(late.refundAmount, 600000);
    expect(late.coinsBack, 100000);
    expect(late.penaltyAmount, 300000);
  });

  test(
    'new customers do not inherit the demo wallet or review history',
    () async {
      MockDatabase.currentUser = null;
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final user = User(
        id: 'isolation-${DateTime.now().microsecondsSinceEpoch}',
        name: 'Khách mới',
        email: 'new@lens.test',
        role: 'client',
      );
      container.read(authUserProvider.notifier).setUser(user);
      expect(
        (await container.read(customerWalletProvider.future)).coinBalance,
        0,
      );
      expect(await container.read(customerReviewsProvider.future), isEmpty);
      expect(container.read(conversationsProvider), isEmpty);
      container
          .read(notificationPreferencesProvider.notifier)
          .update(emailBooking: false);
      expect(
        container.read(notificationPreferencesProvider).emailBooking,
        isFalse,
      );

      container
          .read(authUserProvider.notifier)
          .setUser(MockDatabase.customerUser);
      expect(
        container.read(notificationPreferencesProvider).emailBooking,
        isTrue,
      );
      expect(
        (await container.read(customerWalletProvider.future)).coinBalance,
        greaterThan(0),
      );
      expect(await container.read(customerReviewsProvider.future), isNotEmpty);
    },
  );

  test(
    'discovery and chat search match Vietnamese names without accents',
    () async {
      expect(foldVietnamese('Đà Nẵng'), 'da nang');
      final results = await MockPhotographerRepository().getPhotographers(
        criteria: FilterCriteria(searchQuery: 'da nang'),
      );
      expect(results, isNotEmpty);
      expect(
        results.every((photographer) => photographer.city == 'Đà Nẵng'),
        isTrue,
      );
    },
  );

  test(
    'review updates directory score and account mock data survives re-entry',
    () async {
      final directory = MockPhotographerRepository();
      final before = (await directory.getPhotographers()).firstWhere(
        (item) => item.id == 'p1',
      );
      final accountId = 'review-${DateTime.now().microsecondsSinceEpoch}';
      final reviews = MockCustomerReviewsRepository(
        accountId: accountId,
        photographers: directory,
      );
      await reviews.submitReview(
        bookingId: 'booking-$accountId',
        photographerId: 'p1',
        photographerName: before.name,
        photographerAvatar: before.avatarUrl,
        style: 'Chân dung',
        date: _dateAfter(-1),
        rating: 4,
        comment: 'Buổi chụp đúng giờ, ảnh bàn giao tốt.',
      );
      final after = (await directory.getPhotographers()).firstWhere(
        (item) => item.id == 'p1',
      );
      expect(after.reviewCount, before.reviewCount + 1);
      expect(after.rating, lessThan(before.rating));
      expect(
        await MockCustomerReviewsRepository(
          accountId: accountId,
          photographers: directory,
        ).getMyReviews(),
        hasLength(1),
      );

      final wallet = MockCustomerWalletRepository(accountId: accountId);
      await wallet.addReviewReward(coins: 10000, photographerName: before.name);
      expect(
        (await MockCustomerWalletRepository(
          accountId: accountId,
        ).getWallet()).coinBalance,
        10000,
      );
    },
  );

  test('chat messages stay with their account and reject foreign threads', () {
    final repository = MockCustomerMessagesRepository();
    final accountId = 'chat-${DateTime.now().microsecondsSinceEpoch}';
    final conversation = repository.ensureForPhotographer(
      accountId: accountId,
      photographerId: 'p1',
      name: 'Minh Hà Studio',
      avatar: 'avatar',
    );
    final message = Message(
      id: 'message-1',
      conversationId: conversation.id,
      senderId: accountId,
      senderRole: 'customer',
      text: 'Chào nhiếp ảnh gia',
      timestamp: DateTime.now(),
    );
    repository.addMessage(accountId, message);
    expect(
      MockCustomerMessagesRepository().getMessages(accountId),
      hasLength(1),
    );
    expect(repository.getMessages('another-account'), isEmpty);
    expect(
      () => repository.addMessage('another-account', message),
      throwsStateError,
    );
  });

  testWidgets('protected Customer route sends guests to login with redirect', (
    tester,
  ) async {
    MockDatabase.currentUser = null;
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(goRouterProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.go('/customer_home/bookings');
    await tester.pump();
    await tester.pump();
    expect(router.routeInformationProvider.value.uri.path, '/login');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['redirect'],
      '/customer_home/bookings',
    );
    final loginButton = find.widgetWithText(PrimaryButton, 'Đăng nhập');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(
      router.routeInformationProvider.value.uri.path,
      '/customer_home/bookings',
    );
    expect(container.read(authUserProvider)?.role, 'client');
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('photographers are redirected away from Customer-only routes', (
    tester,
  ) async {
    MockDatabase.currentUser = User(
      id: 'photographer-test',
      name: 'Nhiếp ảnh gia thử nghiệm',
      email: 'creator@lens.test',
      role: 'photographer',
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(goRouterProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.go('/customer_home/wallet');
    await tester.pump();
    await tester.pump();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/customer_home/discovery',
    );
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Customer flow destinations render for the demo account', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final previousErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is NetworkImageLoadException) return;
      previousErrorHandler?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousErrorHandler);
    MockDatabase.currentUser = MockDatabase.customerUser;
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(goRouterProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    for (final path in [
      '/login',
      '/signup',
      '/customer_home/overview',
      '/customer_home/discovery',
      '/customer_home/photographer/p1',
      '/customer_home/photographer/p1/book',
      '/customer_home/bookings',
      '/customer_home/bookings/bk-84920',
      '/customer_home/bookings/bk-84920/gallery',
      '/customer_home/bookings/bk-85102/deposit',
      '/customer_home/bookings/bk-85014/pay',
      '/customer_home/reviews',
      '/customer_home/wallet',
      '/customer_home/settings/profile',
      '/customer_home/settings/account',
      '/customer_home/settings/notifications',
      '/customer_home/messages',
      '/customer_home/messages/c1',
    ]) {
      router.go(path);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(router.routeInformationProvider.value.uri.path, path);
      expect(tester.takeException(), isNull, reason: path);
    }
    router.go('/customer_home/photographer/p1/book?package=pkg_mh_1');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(
      container.read(bookingWizardControllerProvider).selectedPackageId,
      'pkg_mh_1',
    );
    await tester.pump(const Duration(seconds: 2));
  });
}
