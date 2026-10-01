import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lens_app/providers/data_providers.dart';
import 'package:lens_app/features/splash/splash_screen.dart';
import 'package:lens_app/features/landing/ui_gallery_screen.dart';
import 'package:lens_app/features/auth/login_screen.dart';
import 'package:lens_app/features/auth/signup_screen.dart';
import 'package:lens_app/features/customer/customer_home_screen.dart';
import 'package:lens_app/features/customer/discovery/screens/photographers_discovery_screen.dart';
import 'package:lens_app/features/customer/photographer_detail/screens/photographer_detail_screen.dart';
import 'package:lens_app/features/customer/booking_screen.dart';
import 'package:lens_app/features/shared/bookings_list_screen.dart';
import 'package:lens_app/features/customer/bookings/booking_detail_screen.dart';
import 'package:lens_app/features/customer/bookings/delivery_gallery_screen.dart';
import 'package:lens_app/features/customer/messages/customer_conversations_screen.dart';
import 'package:lens_app/features/customer/messages/customer_chat_detail_screen.dart';
import 'package:lens_app/features/customer/payments/deposit_screen.dart';
import 'package:lens_app/features/customer/reviews/reviews_screen.dart';
import 'package:lens_app/features/customer/settings/settings_screen.dart';
import 'package:lens_app/features/customer/wallet/wallet_screen.dart';

import 'customer_shell.dart';

import 'package:lens_app/features/shared/more_tab_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authUserProvider, (previous, next) => refresh.value++);
  ref.onDispose(refresh.dispose);
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: refresh,
    initialLocation: '/splash',
    redirect: (context, state) {
      final path = state.uri.path;
      final user = ref.read(authUserProvider);
      final publicRoute =
          path == '/splash' ||
          path == '/login' ||
          path == '/signup' ||
          path == '/gallery' ||
          path == '/customer_home/discovery' ||
          RegExp(r'^/customer_home/photographer/[^/]+$').hasMatch(path);
      if (publicRoute) return null;
      if (user == null) {
        return Uri(
          path: '/login',
          queryParameters: {'redirect': state.uri.toString()},
        ).toString();
      }
      if (user.role != 'client') return '/customer_home/discovery';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/gallery',
        builder: (context, state) => const UiGalleryScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            LoginScreen(redirect: state.uri.queryParameters['redirect']),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) =>
            SignupScreen(redirect: state.uri.queryParameters['redirect']),
      ),
      GoRoute(
        path: '/customer_home',
        redirect: (context, state) => '/customer_home/overview',
      ),
      GoRoute(
        path: '/customer_home/messages/:id',
        builder: (context, state) => CustomerChatDetailScreen(
          conversationId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/customer_home/bookings/:id',
        builder: (context, state) =>
            BookingDetailScreen(bookingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/customer_home/bookings/:id/gallery',
        builder: (context, state) =>
            DeliveryGalleryScreen(bookingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/customer_home/bookings/:id/deposit',
        builder: (context, state) =>
            DepositScreen(bookingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/customer_home/bookings/:id/pay',
        builder: (context, state) =>
            PaymentScreen(bookingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/customer_home/reviews',
        builder: (context, state) => const ReviewsScreen(),
      ),
      GoRoute(
        path: '/customer_home/wallet',
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/customer_home/settings/profile',
        builder: (context, state) =>
            const SettingsScreen(section: SettingsSection.profile),
      ),
      GoRoute(
        path: '/customer_home/settings/account',
        builder: (context, state) =>
            const SettingsScreen(section: SettingsSection.account),
      ),
      GoRoute(
        path: '/customer_home/settings/notifications',
        builder: (context, state) =>
            const SettingsScreen(section: SettingsSection.notifications),
      ),
      GoRoute(
        path: '/customer_home/photographer/:id/book',
        builder: (context, state) => BookingScreen(
          id: state.pathParameters['id']!,
          packageId: state.uri.queryParameters['package'],
        ),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => CustomerShell(child: child),
        routes: [
          GoRoute(
            path: '/customer_home/overview',
            builder: (context, state) => const CustomerHomeScreen(),
          ),
          GoRoute(
            path: '/customer_home/discovery',
            builder: (context, state) => const PhotographersDiscoveryScreen(),
          ),
          GoRoute(
            path: '/customer_home/photographer/:id',
            builder: (context, state) =>
                PhotographerDetailScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/customer_home/bookings',
            builder: (context, state) => const BookingsListScreen(),
          ),
          GoRoute(
            path: '/customer_home/messages',
            builder: (context, state) => const CustomerConversationsScreen(),
          ),
          GoRoute(
            path: '/customer_home/more',
            builder: (context, state) => const MoreTabScreen(),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
