import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/lens_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../providers/data_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? redirect;
  const LoginScreen({super.key, this.redirect});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: 'customer@lens.com');
  final _passwordController = TextEditingController(text: '123456');
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _quickFillCustomer() {
    setState(() {
      _emailController.text = 'customer@lens.com';
      _passwordController.text = '123456';
      _errorMessage = null;
    });
  }

  void _quickFillPhotographer() {
    setState(() {
      _emailController.text = 'photo@lens.com';
      _passwordController.text = '123456';
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      final user = await ref
          .read(authUserProvider.notifier)
          .login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (!mounted) return;
      if (user.role == 'client') {
        final redirect = widget.redirect;
        final target =
            redirect != null &&
                redirect.startsWith('/customer_home/') &&
                !redirect.startsWith('//')
            ? redirect
            : '/customer_home/overview';
        context.go(target);
      } else {
        context.go('/customer_home/discovery');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _LogoMark(),
                    const SizedBox(height: 22),
                    Text(
                      'Chào mừng trở lại',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.obsidian,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đăng nhập để tiếp tục lưu giữ những khoảnh khắc của bạn.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.steel),
                    ),
                    const SizedBox(height: 24),

                    // Quick-fill Demo Account bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.fog,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.pebble.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.sparkles,
                                size: 14,
                                color: AppColors.ember,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Tài khoản thử nghiệm nhanh (Demo):',
                                  style: AppTypography.labelSm(
                                    color: AppColors.steel,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: _quickFillCustomer,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.snow,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.pebble,
                                      ),
                                      boxShadow: const [
                                        AppTokens.surfaceShadow,
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Trần Khách Hàng',
                                      style: AppTypography.numeric(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.obsidian,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InkWell(
                                  onTap: _quickFillPhotographer,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.snow,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.pebble,
                                      ),
                                      boxShadow: const [
                                        AppTokens.surfaceShadow,
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Nhiếp ảnh gia Demo',
                                      style: AppTypography.numeric(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.steel,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.snow,
                        borderRadius: BorderRadius.circular(
                          AppTokens.largeCardRadius,
                        ),
                        border: Border.all(color: AppColors.pebble),
                        boxShadow: const [AppTokens.surfaceShadow],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 401 FormError Alert Banner
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.crimson.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.crimson.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    LucideIcons.alertCircle,
                                    size: 18,
                                    color: AppColors.crimson,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: AppTypography.bodySm(
                                        color: AppColors.crimson,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          const Text(
                            'Email',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          LensTextField(
                            controller: _emailController,
                            hintText: 'you@example.com',
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập email';
                              }
                              if (!value.contains('@')) {
                                return 'Email không hợp lệ';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Mật khẩu',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          LensTextField(
                            controller: _passwordController,
                            hintText: 'Nhập mật khẩu',
                            obscureText: _obscurePassword,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Vui lòng nhập mật khẩu'
                                : null,
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Hiện mật khẩu'
                                  : 'Ẩn mật khẩu',
                              icon: Icon(
                                _obscurePassword
                                    ? LucideIcons.eyeOff
                                    : LucideIcons.eye,
                                color: AppColors.steel,
                                size: 18,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _showMessage(
                                'Vui lòng liên hệ tổng đài Lens Care hoặc dùng tài khoản Demo.',
                              ),
                              child: const Text('Quên mật khẩu?'),
                            ),
                          ),
                          const SizedBox(height: 4),
                          PrimaryButton(
                            text: 'Đăng nhập',
                            onPressed: _submit,
                            isLoading: _isSubmitting,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Chưa có tài khoản? ',
                          style: TextStyle(
                            color: AppColors.steel,
                            fontSize: 13,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go(
                            Uri(
                              path: '/signup',
                              queryParameters: widget.redirect == null
                                  ? null
                                  : {'redirect': widget.redirect!},
                            ).toString(),
                          ),
                          child: const Text('Đăng ký ngay'),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () => context.go('/customer_home/discovery'),
                      icon: const Icon(LucideIcons.arrowLeft, size: 16),
                      label: const Text('Khám phá thợ chụp trước'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: AppColors.obsidian,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          LucideIcons.aperture,
          color: AppColors.snow,
          size: 30,
        ),
      ),
    );
  }
}
