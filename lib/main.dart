import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lens_app/core/router/app_router.dart';
import 'package:lens_app/core/theme/app_theme.dart';
import 'package:lens_app/providers/data_providers.dart';

import 'core/network/auth_session_store.dart';

final _rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN', null);
  final sessionStore = AuthSessionStore();
  await sessionStore.restore();

  runApp(
    ProviderScope(
      overrides: [authSessionStoreProvider.overrideWithValue(sessionStore)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    if (ref.read(authUserProvider) == null) return;
    try {
      await ref.read(authUserProvider.notifier).refreshProfile();
    } catch (error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              'Không thể tải hồ sơ hiện tại từ Backend: $error',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final goRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Lens App',
      theme: AppTheme.lightTheme,
      scaffoldMessengerKey: _rootScaffoldMessengerKey,
      routerConfig: goRouter,
    );
  }
}
