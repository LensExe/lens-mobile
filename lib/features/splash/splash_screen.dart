import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    if (mounted) {
      // Transition to the main initial route
      final user = ref.read(authUserProvider);
      context.go(
        user?.role == 'client'
            ? '/customer_home/overview'
            : '/customer_home/discovery',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF000000),
      body: Center(
        child: Text(
          'LENS',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 48,
            fontWeight: FontWeight.w700,
            letterSpacing: 4.0,
          ),
        ),
      ),
    );
  }
}
