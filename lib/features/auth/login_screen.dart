import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/lens_text_field.dart';
import '../../core/widgets/lens_logo.dart';
import '../../core/widgets/primary_button.dart';
import '../../providers/data_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? redirect;
  const LoginScreen({super.key, this.redirect});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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

  Future<void> _startGoogleLogin() async {
    if (_isSubmitting) return;
    try {
      await ref.read(authFlowRepositoryProvider).getGoogleAuthorizationUrl();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Google trên ứng dụng LENS'),
          content: const Text(
            'Backend đã cấp URL đăng nhập, nhưng chỉ có một callback frontend dùng chung. Cần callback/deep link để trả handoff code về đúng ứng dụng trước khi Mobile có thể nhận phiên đăng nhập.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) _showMessage(error.toString());
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
                    const Center(
                      child: LensLogo(
                        width: 180,
                        height: 106,
                        semanticLabel: 'Logo Lens',
                      ),
                    ),
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

                    const SizedBox(height: 8),

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
                              onPressed: () => context.push(
                                Uri(
                                  path: '/forgot-password',
                                  queryParameters:
                                      _emailController.text.trim().isEmpty
                                      ? null
                                      : {'email': _emailController.text.trim()},
                                ).toString(),
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
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _isSubmitting ? null : _startGoogleLogin,
                            icon: const Icon(Icons.g_mobiledata, size: 24),
                            label: const Text('Tiếp tục với Google'),
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
