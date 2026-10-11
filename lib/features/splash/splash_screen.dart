import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/lens_logo.dart';
import '../../providers/data_providers.dart';

// import for AppColors if needed, though they hardcoded colors

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Delay for a reasonable time (e.g., 2 seconds)
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    String? profileRefreshError;
    if (ref.read(authUserProvider) != null) {
      try {
        await ref.read(authUserProvider.notifier).refreshProfile();
      } catch (error) {
        profileRefreshError = error.toString();
      }
    }
    if (!mounted) return;
    final user = ref.read(authUserProvider);
    context.go(
      user?.role == 'client'
          ? '/customer_home/overview'
          : '/customer_home/discovery',
    );
    if (profileRefreshError != null && user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không thể tải hồ sơ hiện tại từ Backend: $profileRefreshError',
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
    return const Scaffold(
      backgroundColor: AppColors.mist,
      body: Center(
        child: LensLogo(width: 240, height: 142, semanticLabel: 'Logo Lens'),
      ),
    );
  }
}
