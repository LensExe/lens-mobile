import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';

class GoogleAuthCallbackScreen extends ConsumerStatefulWidget {
  const GoogleAuthCallbackScreen({super.key, required this.code});

  final String code;

  @override
  ConsumerState<GoogleAuthCallbackScreen> createState() =>
      _GoogleAuthCallbackScreenState();
}

class _GoogleAuthCallbackScreenState
    extends ConsumerState<GoogleAuthCallbackScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _exchangeCode());
  }

  Future<void> _exchangeCode() async {
    if (widget.code.isEmpty) {
      if (mounted) {
        setState(() => _error = 'Liên kết đăng nhập thiếu mã xác thực.');
      }
      return;
    }

    try {
      final user = await ref
          .read(authUserProvider.notifier)
          .loginWithGoogleCode(widget.code);
      if (!mounted) return;
      if (user.role != 'client') {
        await ref.read(authUserProvider.notifier).logout();
        if (!mounted) return;
        setState(() {
          _error = 'Tài khoản Google này không thuộc ứng dụng khách hàng.';
        });
        return;
      }
      context.go('/customer_home/overview');
    } catch (error) {
      if (mounted) {
        setState(() => _error = '$error');
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.mist,
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _error == null
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 18),
                    Text('Đang hoàn tất đăng nhập Google…'),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.crimson,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Không thể đăng nhập bằng Google',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.steel),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Quay lại đăng nhập'),
                    ),
                  ],
                ),
        ),
      ),
    ),
  );
}
