import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import 'notification_repository.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  bool _markingRead = false;

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationInboxProvider);
    final unreadCount =
        notifications.asData?.value
            .where((notification) => !notification.isRead)
            .length ??
        0;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          TextButton(
            onPressed: unreadCount == 0 || _markingRead ? null : _markAllRead,
            child: _markingRead
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Đọc tất cả'),
          ),
        ],
      ),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _NotificationError(
          message: 'Không tải được thông báo: $error',
          onRetry: () => ref.invalidate(notificationInboxProvider),
        ),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Bạn chưa có thông báo nào.'))
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(notificationInboxProvider);
                  await ref.read(notificationInboxProvider.future);
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: item.isRead
                            ? AppColors.snow
                            : const Color(0xFFFFF5EF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.pebble),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!item.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 5, right: 10),
                              decoration: const BoxDecoration(
                                color: AppColors.ember,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (item.createdAt != null)
                                      Text(
                                        DateFormat('dd/MM HH:mm')
                                            .format(item.createdAt!),
                                        style: const TextStyle(
                                          color: AppColors.steel,
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                                if (item.message.isNotEmpty) ...[
                                  const SizedBox(height: 5),
                                  Text(item.message),
                                ],
                                const SizedBox(height: 5),
                                Text(
                                  _typeLabel(item.type),
                                  style: const TextStyle(
                                    color: AppColors.steel,
                                    fontSize: 10,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Future<void> _markAllRead() async {
    setState(() => _markingRead = true);
    try {
      await ref.read(notificationRepositoryProvider).markAllRead();
      ref.invalidate(notificationInboxProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không cập nhật được thông báo: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _markingRead = false);
    }
  }
}

class _NotificationError extends StatelessWidget {
  const _NotificationError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    ),
  );
}

String _typeLabel(String type) => switch (type) {
  'welcome' => 'CHÀO MỪNG',
  'order_placed' => 'ĐẶT LỊCH',
  'payment_success' => 'THANH TOÁN',
  'promotion_started' => 'ƯU ĐÃI',
  _ => type.toUpperCase(),
};
