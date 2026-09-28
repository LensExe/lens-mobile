import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lens_app/features/splash/splash_screen.dart';
import 'package:lens_app/features/landing/ui_gallery_screen.dart';
import 'package:lens_app/features/auth/login_screen.dart';
import 'package:lens_app/features/customer/customer_home_screen.dart';
import 'package:lens_app/features/customer/search_screen.dart';
import 'package:lens_app/features/customer/photographer_detail_screen.dart';
import 'package:lens_app/features/customer/booking_screen.dart';
import 'package:lens_app/features/shared/bookings_list_screen.dart';
import 'package:lens_app/features/customer/bookings/booking_detail_screen.dart';
import 'package:lens_app/features/customer/bookings/delivery_gallery_screen.dart';
import 'package:lens_app/features/customer/messages/customer_conversations_screen.dart';
import 'package:lens_app/features/customer/messages/customer_chat_detail_screen.dart';

import 'customer_shell.dart';
import 'package:lens_app/features/shared/more_tab_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
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
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/customer_home/messages/:id',
        builder: (context, state) => CustomerChatDetailScreen(conversationId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/customer_home/bookings/:id',
        builder: (context, state) => BookingDetailScreen(bookingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/customer_home/bookings/:id/gallery',
        builder: (context, state) => DeliveryGalleryScreen(bookingId: state.pathParameters['id']!),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => CustomerShell(child: child),
        routes: [
          GoRoute(
            path: '/customer_home',
            builder: (context, state) => const CustomerHomeScreen(),
          ),
          GoRoute(
            path: '/customer_home/search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/customer_home/photographer/:id',
            builder: (context, state) => PhotographerDetailScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/customer_home/photographer/:id/book',
            builder: (context, state) => BookingScreen(id: state.pathParameters['id']!),
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
});
