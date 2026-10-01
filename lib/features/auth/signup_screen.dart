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
  String _selectedRole = 'client'; // 'client' | 'photographer'
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authUserProvider.notifier)
          .signup(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            role: _selectedRole,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tạo tài khoản thành công! Chào mừng bạn đến với Lens.',
          ),
          backgroundColor: AppColors.emerald,
        ),
      );
      final redirect = widget.redirect;
      context.go(
        _selectedRole == 'client' &&
                redirect != null &&
                redirect.startsWith('/customer_home/') &&
                !redirect.startsWith('//')
            ? redirect
            : '/customer_home/overview',
      );
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
                      const SizedBox(height: 20),

                      // API Error Banner (e.g. 409 Email đã tồn tại)
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.crimson.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.crimson.withValues(alpha: 0.3),
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
                        const SizedBox(height: 18),
                      ],

                      // Step 1: Role Selection Radio
                      const Text(
                        'Mục đích của bạn là gì?',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _RoleCard(
                              icon: LucideIcons.user,
                              title: 'Thuê thợ ảnh',
                              subtitle: 'Tôi là Khách hàng',
                              isSelected: _selectedRole == 'client',
                              onTap: () =>
                                  setState(() => _selectedRole = 'client'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _RoleCard(
                              icon: LucideIcons.camera,
                              title: 'Nhận lịch chụp',
                              subtitle: 'Tôi là Nhiếp ảnh gia',
                              isSelected: _selectedRole == 'photographer',
                              onTap: () => setState(
                                () => _selectedRole = 'photographer',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Step 2: Name
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

                      // Step 3: Primary CTA Button
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

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.ember.withValues(alpha: 0.06)
              : AppColors.fog,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.ember
                : AppColors.pebble.withValues(alpha: 0.6),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.ember : AppColors.steel,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: AppTypography.titleMd(
                fontSize: 12.5,
                color: isSelected ? AppColors.ember : AppColors.obsidian,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              subtitle,
              style: AppTypography.labelSm(
                fontSize: 10,
                color: AppColors.steel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
