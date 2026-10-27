import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/customer_wallet_model.dart';
import '../../../providers/data_providers.dart';

class WalletWithdrawalDialog extends ConsumerStatefulWidget {
  const WalletWithdrawalDialog({super.key, required this.availableBalance});

  final int availableBalance;

  static Future<WalletWithdrawalRequest?> show(
    BuildContext context, {
    required int availableBalance,
  }) => showDialog<WalletWithdrawalRequest>(
    context: context,
    builder: (context) =>
        WalletWithdrawalDialog(availableBalance: availableBalance),
  );

  @override
  ConsumerState<WalletWithdrawalDialog> createState() =>
      _WalletWithdrawalDialogState();
}

class _WalletWithdrawalDialogState
    extends ConsumerState<WalletWithdrawalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _bankCodeController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  late final String _idempotencyKey;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final userId = ref.read(authUserProvider)?.id ?? 'customer';
    _idempotencyKey =
        'mobile-withdrawal:$userId:${DateTime.now().microsecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _bankCodeController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppColors.snow,
    title: Text(
      'Yêu cầu rút tiền',
      style: AppTypography.titleMd(color: AppColors.obsidian),
    ),
    content: SingleChildScrollView(
      child: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Số dư khả dụng: ${AppTypography.formatCurrency(widget.availableBalance)} ₫',
                  style: AppTypography.bodySm(color: AppColors.steel),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Số tiền muốn rút',
                  suffixText: '₫',
                ),
                validator: _validateAmount,
                onChanged: (_) => setState(() => _errorMessage = null),
              ),
              TextFormField(
                controller: _reasonController,
                maxLength: 1000,
                decoration: const InputDecoration(labelText: 'Lý do rút tiền'),
                validator: (value) =>
                    _validateLength(value, min: 1, max: 1000, label: 'Lý do'),
                onChanged: (_) => setState(() => _errorMessage = null),
              ),
              TextFormField(
                controller: _bankCodeController,
                maxLength: 32,
                decoration: const InputDecoration(
                  labelText: 'Mã ngân hàng (BIN hoặc mã ngân hàng)',
                ),
                validator: (value) => _validateLength(
                  value,
                  min: 2,
                  max: 32,
                  label: 'Mã ngân hàng',
                ),
                onChanged: (_) => setState(() => _errorMessage = null),
              ),
              TextFormField(
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 34,
                decoration: const InputDecoration(
                  labelText: 'Số tài khoản nhận tiền',
                ),
                validator: (value) {
                  final account = value?.trim() ?? '';
                  if (!RegExp(r'^[0-9]{4,34}$').hasMatch(account)) {
                    return 'Số tài khoản cần có từ 4 đến 34 chữ số.';
                  }
                  return null;
                },
                onChanged: (_) => setState(() => _errorMessage = null),
              ),
              TextFormField(
                controller: _accountNameController,
                maxLength: 120,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Tên chủ tài khoản',
                ),
                validator: (value) => _validateLength(
                  value,
                  min: 2,
                  max: 120,
                  label: 'Tên chủ tài khoản',
                ),
                onChanged: (_) => setState(() => _errorMessage = null),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _errorMessage!,
                    style: AppTypography.bodySm(color: AppColors.crimson),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Yêu cầu sẽ được giữ số dư và chờ quản trị viên xử lý.',
                  style: AppTypography.bodySm(color: AppColors.steel),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
        child: const Text('Đóng'),
      ),
      FilledButton(
        onPressed: _isSubmitting ? null : _submit,
        child: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Gửi yêu cầu'),
      ),
    ],
  );

  String? _validateAmount(String? value) {
    final amount = int.tryParse(value?.trim() ?? '');
    if (amount == null || amount < 10000) {
      return 'Số tiền tối thiểu là 10.000 ₫.';
    }
    if (amount > widget.availableBalance) {
      return 'Số tiền vượt quá số dư khả dụng.';
    }
    if (amount > 9000000000000) {
      return 'Số tiền vượt giới hạn Backend.';
    }
    return null;
  }

  String? _validateLength(
    String? value, {
    required int min,
    required int max,
    required String label,
  }) {
    final text = value?.trim() ?? '';
    if (text.length < min) return '$label cần có ít nhất $min ký tự.';
    if (text.length > max) return '$label không được vượt quá $max ký tự.';
    return null;
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;
    final amount = int.parse(_amountController.text.trim());
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await ref
          .read(customerWalletRepositoryProvider)
          .requestWithdrawal(
            amount: amount,
            reason: _reasonController.text.trim(),
            bankCode: _bankCodeController.text.trim(),
            accountNumber: _accountNumberController.text.trim(),
            accountName: _accountNameController.text.trim(),
            idempotencyKey: _idempotencyKey,
          );
      if (!mounted) return;
      ref.invalidate(customerWalletProvider);
      Navigator.of(context).pop(result);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = error is ApiException
            ? error.message
            : 'Không thể gửi yêu cầu. Hãy thử lại.';
      });
    }
  }
}
