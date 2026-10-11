import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/data_providers.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otp = TextEditingController();
  bool _busy = false;
  bool _sent = false;
  bool _verified = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      final message = await ref
          .read(authFlowRepositoryProvider)
          .sendEmailVerificationOtp();
      if (!mounted) return;
      setState(() {
        _otp.clear();
        _sent = true;
        _message = message;
      });
    } catch (error) {
      if (mounted) setState(() => _error = _errorText(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      final message = await ref
          .read(authFlowRepositoryProvider)
          .verifyEmail(_otp.text);
      if (!mounted) return;
      setState(() {
        _verified = true;
        _message = message;
      });
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
    final email = ref.watch(authUserProvider)?.email ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác minh email'),
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
                  _verified ? 'Email đã được xác minh' : 'Xác minh tài khoản',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  _verified
                      ? (_message ?? 'Xác minh email thành công.')
                      : 'Mã OTP sẽ được gửi đến email đang đăng nhập.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email tài khoản'),
                  subtitle: Text(email),
                ),
                if (!_verified) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Theo Backend source hiện tại, phần gửi OTP qua email đang tắt. Nếu không nhận được mã, cần bật Notification/Mail service ở Backend.',
                    style: TextStyle(color: Colors.deepOrange, height: 1.4),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  _StatusMessage(message: _error!, error: true),
                ],
                if (_message != null && !_verified) ...[
                  const SizedBox(height: 12),
                  _StatusMessage(message: _message!),
                ],
                const SizedBox(height: 20),
                if (_verified)
                  FilledButton(
                    onPressed: () => context.pop(),
                    child: const Text('Hoàn tất'),
                  )
                else if (!_sent)
                  FilledButton.icon(
                    onPressed: _busy ? null : _send,
                    icon: const Icon(Icons.mark_email_read_outlined),
                    label: Text(_busy ? 'Đang gửi...' : 'Gửi mã OTP'),
                  )
                else ...[
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _otp,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Mã OTP 6 chữ số',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => (value ?? '').length == 6
                          ? null
                          : 'Mã OTP gồm 6 chữ số',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy ? null : _verify,
                    child: Text(_busy ? 'Đang xác minh...' : 'Xác minh email'),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: _busy ? null : _send,
                      child: const Text('Gửi lại mã OTP'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message, this.error = false});

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: error
          ? Colors.red.withValues(alpha: 0.08)
          : Colors.green.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      message,
      style: TextStyle(
        color: error ? Colors.red.shade800 : Colors.green.shade800,
      ),
    ),
  );
}
