import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/customer_wallet_model.dart';
import '../../../providers/data_providers.dart';

class WalletPayoutDestinationCard extends ConsumerWidget {
  const WalletPayoutDestinationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinationState = ref.watch(customerPayoutDestinationProvider);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.snow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.pebble),
        boxShadow: const [AppTokens.surfaceShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.landmark,
                size: 19,
                color: AppColors.obsidian,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Tài khoản nhận tiền',
                  style: AppTypography.titleMd(
                    fontSize: 15,
                    color: AppColors.obsidian,
                  ),
                ),
              ),
              destinationState.when(
                loading: () => const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.ember,
                  ),
                ),
                error: (_, _) => IconButton(
                  tooltip: 'Tải lại tài khoản nhận tiền',
                  onPressed: () =>
                      ref.invalidate(customerPayoutDestinationProvider),
                  icon: const Icon(LucideIcons.refreshCw, size: 17),
                ),
                data: (destination) => TextButton.icon(
                  onPressed: () => WalletPayoutDestinationDialog.show(
                    context,
                    current: destination,
                  ),
                  icon: Icon(
                    destination.isConfigured
                        ? LucideIcons.pencil
                        : LucideIcons.plus,
                    size: 15,
                  ),
                  label: Text(destination.isConfigured ? 'Đổi' : 'Thêm'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tài khoản này được dùng mặc định khi bạn rút số dư ví.',
            style: AppTypography.bodySm(fontSize: 12, color: AppColors.steel),
          ),
          const SizedBox(height: 14),
          destinationState.when(
            loading: () => Text(
              'Đang tải thông tin tài khoản…',
              style: AppTypography.bodySm(color: AppColors.steel),
            ),
            error: (error, _) => Row(
              children: [
                Expanded(
                  child: Text(
                    error is ApiException
                        ? error.message
                        : 'Không tải được tài khoản nhận tiền.',
                    style: AppTypography.bodySm(color: AppColors.crimson),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(customerPayoutDestinationProvider),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
            data: (destination) => destination.isConfigured
                ? _ConfiguredDestination(destination: destination)
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: AppColors.fog,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.pebble),
                    ),
                    child: Text(
                      'Bạn chưa lưu tài khoản ngân hàng. Hãy thêm tài khoản trước khi rút tiền.',
                      style: AppTypography.bodySm(
                        fontSize: 12,
                        color: AppColors.steel,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ConfiguredDestination extends StatelessWidget {
  const _ConfiguredDestination({required this.destination});

  final CustomerPayoutDestination destination;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: AppColors.fog,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.pebble),
    ),
    child: Row(
      children: [
        const Icon(LucideIcons.landmark, size: 19, color: AppColors.steel),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                destination.accountName ?? 'Tài khoản đã lưu',
                style: AppTypography.labelMd(color: AppColors.obsidian),
              ),
              const SizedBox(height: 3),
              Text(
                [destination.bankCode, destination.accountNumberMasked]
                    .whereType<String>()
                    .where((value) => value.isNotEmpty)
                    .join(' · '),
                style: AppTypography.bodySm(
                  fontSize: 11.5,
                  color: AppColors.steel,
                ),
              ),
            ],
          ),
        ),
        const Icon(LucideIcons.check, size: 17, color: AppColors.emerald),
      ],
    ),
  );
}

class WalletPayoutDestinationDialog extends ConsumerStatefulWidget {
  const WalletPayoutDestinationDialog({super.key, this.current});

  final CustomerPayoutDestination? current;

  static Future<void> show(
    BuildContext context, {
    CustomerPayoutDestination? current,
  }) => showDialog<void>(
    context: context,
    builder: (_) => WalletPayoutDestinationDialog(current: current),
  );

  @override
  ConsumerState<WalletPayoutDestinationDialog> createState() =>
      _WalletPayoutDestinationDialogState();
}

class _WalletPayoutDestinationDialogState
    extends ConsumerState<WalletPayoutDestinationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _bankCodeController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _bankCodeController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppColors.snow,
    title: Text(
      widget.current?.isConfigured == true
          ? 'Đổi tài khoản nhận tiền'
          : 'Thêm tài khoản nhận tiền',
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
                  'Tài khoản được lưu an toàn; màn hình ví chỉ hiển thị bốn số cuối.',
                  style: AppTypography.bodySm(color: AppColors.steel),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _bankCodeController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Mã BIN ngân hàng',
                  hintText: '6 chữ số',
                ),
                validator: (value) =>
                    RegExp(r'^\d{6}$').hasMatch(value?.trim() ?? '')
                    ? null
                    : 'Mã BIN cần có đúng 6 chữ số.',
                onChanged: (_) => setState(() => _error = null),
              ),
              TextFormField(
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 34,
                decoration: const InputDecoration(
                  labelText: 'Số tài khoản nhận tiền',
                ),
                validator: (value) =>
                    RegExp(r'^[0-9]{4,34}$').hasMatch(value?.trim() ?? '')
                    ? null
                    : 'Số tài khoản cần có từ 4 đến 34 chữ số.',
                onChanged: (_) => setState(() => _error = null),
              ),
              TextFormField(
                controller: _accountNameController,
                textCapitalization: TextCapitalization.words,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Tên chủ tài khoản',
                ),
                validator: (value) {
                  final name = value?.trim() ?? '';
                  if (name.length < 2 || name.length > 120) {
                    return 'Tên cần có từ 2 đến 120 ký tự.';
                  }
                  return null;
                },
                onChanged: (_) => setState(() => _error = null),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: AppTypography.bodySm(color: AppColors.crimson),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.of(context).pop(),
        child: const Text('Huỷ'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Lưu tài khoản'),
      ),
    ],
  );

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(customerWalletRepositoryProvider)
          .savePayoutDestination(
            bankCode: _bankCodeController.text.trim(),
            accountNumber: _accountNumberController.text.trim(),
            accountName: _accountNameController.text.trim(),
          );
      ref.invalidate(customerPayoutDestinationProvider);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã lưu tài khoản nhận tiền.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error is ApiException
            ? error.message
            : 'Không thể lưu tài khoản. Vui lòng thử lại.';
      });
    }
  }
}
