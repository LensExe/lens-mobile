import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/data_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail ?? '');
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  int _step = 0;
  bool _busy = false;
  bool _complete = false;
  String? _resetToken;
  String? _notice;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final auth = ref.read(authFlowRepositoryProvider);
      if (_step == 0) {
        final message = await auth.sendForgotPasswordOtp(_email.text);
        if (!mounted) return;
        setState(() {
          _step = 1;
          _notice = message;
        });
      } else if (_step == 1) {
        final token = await auth.verifyForgotPasswordOtp(
          email: _email.text,
          otp: _otp.text,
        );
        if (!mounted) return;
        setState(() {
          _resetToken = token;
          _step = 2;
          _notice = 'Mã xác minh hợp lệ. Hãy đặt mật khẩu mới.';
        });
      } else {
        final token = _resetToken;
        if (token == null) {
          throw StateError('Mã xác minh đã hết hạn. Hãy xác minh lại email.');
        }
        await auth.resetPassword(
          resetToken: token,
          newPassword: _password.text,
          confirmPassword: _confirmPassword.text,
        );
        if (!mounted) return;
        setState(() {
          _complete = true;
          _notice = 'Đã đổi mật khẩu. Bạn có thể đăng nhập bằng mật khẩu mới.';
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = _errorText(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final message = await ref
          .read(authFlowRepositoryProvider)
          .sendForgotPasswordOtp(_email.text);
      if (mounted) {
        setState(() {
          _otp.clear();
          _notice = message;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = _errorText(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _errorText(Object error) => error.toString().replaceFirst(
    RegExp(r'^(Exception|ApiException):\s*'),
    '',
  );

  @override
  Widget build(BuildContext context) {
    final title = _complete
        ? 'Đã đặt lại mật khẩu'
        : switch (_step) {
            0 => 'Khôi phục mật khẩu',
            1 => 'Nhập mã xác minh',
            _ => 'Tạo mật khẩu mới',
          };
    final subtitle = _complete
        ? _notice ?? ''
        : switch (_step) {
            0 => 'Nhập email tài khoản để nhận mã xác minh.',
            1 => 'Nhập mã 6 chữ số cho tài khoản ${_email.text.trim()}.',
            _ => 'Mật khẩu mới phải có ít nhất 6 ký tự.',
          };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Khôi phục tài khoản'),
        leading: IconButton(
          tooltip: 'Quay lại',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  _MessageBox(message: _error!, error: true),
                  const SizedBox(height: 16),
                ],
                if (_notice != null && !_complete) ...[
                  _MessageBox(message: _notice!),
                  const SizedBox(height: 16),
                ],
                if (_step > 0 && !_complete) ...[
                  const _MessageBox(
                    message: 'Theo Backend source hiện tại, phần gửi OTP qua email đang tắt. Nếu không nhận được mã, cần bật Notification/Mail service ở Backend.',
                    warning: true,
                  ),
                  const SizedBox(height: 16),
                ],
                if (_complete)
                  FilledButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Về đăng nhập'),
                  )
                else
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_step == 0)
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'Email tài khoản',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch((value ?? '').trim())
                                ? null
                                : 'Email không hợp lệ',
                          ),
                        if (_step == 1) ...[
                          TextFormField(
                            controller: _otp,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Mã OTP',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => (value ?? '').length == 6
                                ? null
                                : 'Mã OTP gồm 6 chữ số',
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _busy ? null : _resend,
                              child: const Text('Gửi lại mã'),
                            ),
                          ),
                        ],
                        if (_step == 2) ...[
                          TextFormField(
                            controller: _password,
                            obscureText: true,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: const InputDecoration(
                              labelText: 'Mật khẩu mới',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => (value ?? '').length >= 6
                                ? null
                                : 'Mật khẩu cần ít nhất 6 ký tự',
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _confirmPassword,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Nhập lại mật khẩu mới',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value == _password.text
                                ? null
                                : 'Mật khẩu xác nhận chưa khớp',
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _busy ? null : _submit,
                          child: Text(
                            _busy
                                ? 'Đang xử lý...'
                                : switch (_step) {
                                    0 => 'Gửi mã OTP',
                                    1 => 'Xác minh mã',
                                    _ => 'Đặt lại mật khẩu',
                                  },
                          ),
                        ),
                        if (_step > 0) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => setState(() {
                                    _step = 0;
                                    _resetToken = null;
                                    _otp.clear();
                                    _error = null;
                                    _notice = null;
                                  }),
                            child: const Text('Dùng email khác'),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({
    required this.message,
    this.error = false,
    this.warning = false,
  });

  final String message;
  final bool error;
  final bool warning;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: error
          ? Colors.red.withValues(alpha: 0.08)
          : warning
          ? Colors.orange.withValues(alpha: 0.1)
          : Colors.green.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      message,
      style: TextStyle(
        color: error
            ? Colors.red.shade800
            : warning
            ? Colors.orange.shade900
            : Colors.green.shade800,
      ),
    ),
  );
}
