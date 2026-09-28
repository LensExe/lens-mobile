import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/data_providers.dart';

class CustomerConversationsScreen extends ConsumerWidget {
  const CustomerConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        backgroundColor: AppColors.mist,
        elevation: 0,
        title: const Text(
          'Tin nhắn',
          style: TextStyle(
            color: AppColors.obsidian,
            fontWeight: FontWeight.w700,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: conversations.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conv = conversations[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      context.push('/customer_home/messages/${conv.id}');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.snow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.pebble, width: 1.0),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage(conv.otherPartyAvatar),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  conv.otherPartyName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: AppColors.obsidian,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  conv.lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: conv.unreadCount > 0 ? AppColors.obsidian : AppColors.steel,
                                    fontWeight: conv.unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${conv.updatedAt.hour}:${conv.updatedAt.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.steel,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (conv.unreadCount > 0)
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.destructive,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    conv.unreadCount.toString(),
                                    style: const TextStyle(
                                      color: AppColors.snow,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.fog,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.messageSquare, size: 48, color: AppColors.ash),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chưa có tin nhắn nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.obsidian,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Khi bạn đặt lịch chụp, bạn có thể trò\nchuyện với thợ chụp tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.steel, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
