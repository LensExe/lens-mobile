import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/network/api_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/lens_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../providers/data_providers.dart';

class SignupScreen extends ConsumerStatefulWidget {
  final String? redirect;
  const SignupScreen({super.key, this.redirect});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authUserProvider.notifier)
          .signup(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            role: 'client',
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(
                  LucideIcons.checkCircle2,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tạo tài khoản thành công! Chào mừng bạn đến với Lens.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.emerald,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            duration: const Duration(seconds: 3),
          ),
        );

      final redirect = widget.redirect;
      context.go(
        redirect != null &&
                redirect.startsWith('/customer_home/') &&
                !redirect.startsWith('//')
            ? redirect
            : '/customer_home/overview',
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage(_extractErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _extractErrorMessage(Object exception) {
    if (exception is ApiException) {
      final msg = exception.message;
      final code = exception.statusCode;

      if (code == 409 ||
          msg.contains('409') ||
          msg.contains('Keycloak request failed with status 401') ||
          msg.toLowerCase().contains('already exists') ||
          msg.toLowerCase().contains('user exists') ||
          msg.toLowerCase().contains('đã tồn tại')) {
        return 'Email này đã được sử dụng. Vui lòng đăng nhập hoặc sử dụng email khác.';
      }

      if (code == 400 ||
          code == 422 ||
          msg.contains('Keycloak request failed with status 400') ||
          msg.toLowerCase().contains('invalid')) {
        return 'Thông tin đăng ký không hợp lệ. Vui lòng kiểm tra lại.';
      }

      if (msg.contains('Keycloak') ||
          (code != null && code >= 500)) {
        return 'Hệ thống đang bảo trì hoặc gặp sự cố tạm thời. Vui lòng thử lại sau.';
      }

      if (msg.contains('Không thể kết nối')) {
        return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng.';
      }

      if (msg.contains('Exception') ||
          msg.contains('DioException') ||
          msg.contains('HTTP ') ||
          msg.contains('status code')) {
        return 'Đăng ký không thành công. Vui lòng thử lại sau.';
      }

      return msg;
    }

    if (exception is ApiConfigurationException) {
      return 'Lỗi cấu hình hệ thống: Địa chỉ máy chủ không hợp lệ.';
    }

    final message = exception
        .toString()
        .replaceFirst('Bad state: ', '')
        .replaceFirst('Exception: ', '');

    if (message.contains('API_BASE_URL')) {
      return 'Chưa cấu hình địa chỉ máy chủ (API_BASE_URL).';
    }
    if (message.contains('SocketException') ||
        message.contains('Connection refused') ||
        message.contains('Network is unreachable') ||
        message.contains('Failed host lookup')) {
      return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng.';
    }
    if (message.contains('ProviderException') ||
        message.contains('stack trace')) {
      return 'Không thể kết nối đến hệ thống máy chủ. Vui lòng thử lại sau.';
    }

    return 'Đăng ký không thành công. Vui lòng kiểm tra lại thông tin và thử lại.';
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                LucideIcons.alertCircle,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.crimson,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        title: const Text('Tạo tài khoản'),
        elevation: 0,
        backgroundColor: AppColors.mist,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.obsidian),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(
                  Uri(
                    path: '/login',
                    queryParameters: widget.redirect == null
                        ? null
                        : {'redirect': widget.redirect!},
                  ).toString(),
                ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Container(
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
                      Text(
                        'Bắt đầu với Lens',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.obsidian,
                            ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Đăng ký tài khoản miễn phí để tìm kiếm và đặt lịch nhiếp ảnh gia.',
                        style: TextStyle(color: AppColors.steel, fontSize: 13),
                      ),
                      const SizedBox(height: 22),

                      // Name
                      const Text(
                        'Họ và tên',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      LensTextField(
                        controller: _nameController,
                        hintText: 'Nhập họ và tên đầy đủ',
                        validator: (value) =>
                            value == null || value.trim().length < 2
                            ? 'Vui lòng nhập họ tên đầy đủ'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Email
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
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Email không hợp lệ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password (min 8 chars)
                      const Text(
                        'Mật khẩu (tối thiểu 8 ký tự)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      LensTextField(
                        controller: _passwordController,
                        hintText: 'Tối thiểu 8 ký tự',
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập mật khẩu';
                          }
                          if (value.length < 8) {
                            return 'Mật khẩu cần ít nhất 8 ký tự';
                          }
                          return null;
                        },
                        suffixIcon: IconButton(
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
                      const SizedBox(height: 24),

                      // Primary CTA Button
                      PrimaryButton(
                        text: 'Tạo tài khoản',
                        onPressed: _submit,
                        isLoading: _isSubmitting,
                      ),
                      const SizedBox(height: 14),

                      // Link to Login
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Đã có tài khoản? ',
                            style: TextStyle(
                              color: AppColors.steel,
                              fontSize: 13,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go(
                              Uri(
                                path: '/login',
                                queryParameters: widget.redirect == null
                                    ? null
                                    : {'redirect': widget.redirect!},
                              ).toString(),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Đăng nhập'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
