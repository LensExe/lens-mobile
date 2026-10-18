import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/lens_tab_app_bar.dart';
import 'api_customer_chat_repository.dart';

class CustomerConversationsScreen extends ConsumerStatefulWidget {
  const CustomerConversationsScreen({super.key});

  @override
  ConsumerState<CustomerConversationsScreen> createState() =>
      _CustomerConversationsScreenState();
}

class _CustomerConversationsScreenState
    extends ConsumerState<CustomerConversationsScreen> {
  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(customerConversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const LensTabAppBar(title: 'Tin nhắn'),
      body: RefreshIndicator(
        color: AppColors.ember,
        onRefresh: () =>
            ref.read(customerConversationsProvider.notifier).refresh(),
        child: conversations.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 180),
              Center(child: CircularProgressIndicator(color: AppColors.ember)),
            ],
          ),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppTokens.pageHorizontal),
            children: [
              const SizedBox(height: 70),
              _MessageError(
                message: 'Không tải được hội thoại: $error',
                onRetry: () =>
                    ref.read(customerConversationsProvider.notifier).refresh(),
              ),
            ],
          ),
          data: (items) => items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.pageHorizontal,
                    100,
                    AppTokens.pageHorizontal,
                    130,
                  ),
                  children: const [_EmptyConversations()],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.pageHorizontal,
                    10,
                    AppTokens.pageHorizontal,
                    120,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 9),
                  itemBuilder: (context, index) {
                    final conversation = items[index];
                    return _ConversationTile(
                      conversation: conversation,
                      onTap: () => context.push(
                        '/customer_home/conversation/${conversation.id}',
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.onTap});

  final CustomerChatConversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unreadCount > 0;
    return Material(
      color: AppColors.snow,
      borderRadius: BorderRadius.circular(AppTokens.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.cardRadius),
            border: Border.all(color: AppColors.pebble),
            boxShadow: const [AppTokens.surfaceShadow],
          ),
          child: Row(
            children: [
              _Avatar(
                name: conversation.participantName,
                imageUrl: conversation.participantAvatar,
                unread: unread,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.participantName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                AppTypography.labelMd(color: AppColors.obsidian)
                                    .copyWith(
                                      fontWeight: unread
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                    ),
                          ),
                        ),
                        if (conversation.lastMessageAt != null)
                          Text(
                            _timeLabel(conversation.lastMessageAt!),
                            style: AppTypography.bodySm(
                              fontSize: 11,
                              color: unread ? AppColors.ember : AppColors.steel,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      conversation.lastMessage.isEmpty
                          ? 'Bắt đầu cuộc trò chuyện'
                          : conversation.lastMessage,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm(
                        color: unread ? AppColors.obsidian : AppColors.steel,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread) ...[
                const SizedBox(width: 8),
                Container(
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.ember,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${conversation.unreadCount}',
                    style: AppTypography.labelSm(color: AppColors.snow),
                  ),
                ),
              ] else ...[
                const SizedBox(width: 6),
                const Icon(
                  LucideIcons.chevronRight,
                  color: AppColors.steel,
                  size: 17,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.imageUrl, required this.unread});
  final String name;
  final String? imageUrl;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final image = imageUrl?.trim();
    return Container(
      width: 50,
      height: 50,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: unread ? AppColors.ember.withValues(alpha: 0.12) : AppColors.fog,
        shape: BoxShape.circle,
      ),
      child: image == null || image.isEmpty
          ? Center(
              child: Text(
                initial,
                style: AppTypography.titleMd(
                  color: unread ? AppColors.ember : AppColors.steel,
                ),
              ),
            )
          : Image.network(
              image,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  initial,
                  style: AppTypography.titleMd(color: AppColors.steel),
                ),
              ),
            ),
    );
  }
}

class _EmptyConversations extends StatelessWidget {
  const _EmptyConversations();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
    decoration: BoxDecoration(
      color: AppColors.snow,
      borderRadius: BorderRadius.circular(AppTokens.cardRadius),
      border: Border.all(color: AppColors.pebble),
      boxShadow: const [AppTokens.surfaceShadow],
    ),
    child: const Column(
      children: [
        Icon(LucideIcons.messageSquareText, size: 34, color: AppColors.steel),
        SizedBox(height: 14),
        Text(
          'Chưa có tin nhắn',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 7),
        Text(
          'Bạn có thể nhắn với nhiếp ảnh gia từ hồ sơ hoặc chi tiết booking. Tin nhắn và phản hồi AI sẽ hiển thị tại đây.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.steel, height: 1.4),
        ),
      ],
    ),
  );
}

class _MessageError extends StatelessWidget {
  const _MessageError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.snow,
      borderRadius: BorderRadius.circular(AppTokens.cardRadius),
      border: Border.all(color: AppColors.pebble),
    ),
    child: Column(
      children: [
        const Icon(LucideIcons.wifiOff, color: AppColors.steel, size: 30),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(LucideIcons.refreshCw, size: 16),
          label: const Text('Thử lại'),
        ),
      ],
    ),
  );
}

String _timeLabel(DateTime time) {
  final now = DateTime.now();
  if (DateUtils.isSameDay(time, now)) return DateFormat('HH:mm').format(time);
  if (DateUtils.isSameDay(time, now.subtract(const Duration(days: 1)))) {
    return 'Hôm qua';
  }
  return DateFormat('dd/MM').format(time);
}
