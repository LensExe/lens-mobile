import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/models.dart';
import '../../../providers/data_providers.dart';

class CustomerConversationsScreen extends ConsumerStatefulWidget {
  const CustomerConversationsScreen({super.key});

  @override
  ConsumerState<CustomerConversationsScreen> createState() =>
      _CustomerConversationsScreenState();
}

class _CustomerConversationsScreenState
    extends ConsumerState<CustomerConversationsScreen> {
  final _searchController = TextEditingController();
  bool _unreadOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationsProvider);
    final query = _searchController.text.trim().toLowerCase();
    final visible = conversations.where((conversation) {
      final matchesQuery =
          query.isEmpty ||
          conversation.otherPartyName.toLowerCase().contains(query) ||
          conversation.lastMessage.toLowerCase().contains(query);
      final matchesUnread = !_unreadOnly || conversation.unreadCount > 0;
      return matchesQuery && matchesUnread;
    }).toList();

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Tìm cuộc trò chuyện...',
                prefixIcon: const Icon(LucideIcons.search, size: 19),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(LucideIcons.x, size: 18),
                      ),
                filled: true,
                fillColor: AppColors.snow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Tất cả',
                  selected: !_unreadOnly,
                  onTap: () => setState(() => _unreadOnly = false),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Chưa đọc',
                  count: conversations
                      .where((conversation) => conversation.unreadCount > 0)
                      .length,
                  selected: _unreadOnly,
                  onTap: () => setState(() => _unreadOnly = true),
                ),
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? _buildEmptyState(filtered: conversations.isNotEmpty)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final conversation = visible[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ConversationCard(
                          conversation: conversation,
                          onTap: () {
                            ref
                                .read(conversationsProvider.notifier)
                                .markRead(conversation.id);
                            context.push(
                              '/customer_home/messages/${conversation.id}',
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required bool filtered}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.fog,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.messageSquare,
                size: 48,
                color: AppColors.ash,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              filtered
                  ? 'Không có cuộc trò chuyện phù hợp'
                  : 'Chưa có tin nhắn nào',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.obsidian,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              filtered
                  ? 'Thử đổi từ khoá hoặc bộ lọc để xem các cuộc trò chuyện khác.'
                  : 'Khi bạn đặt lịch chụp, bạn có thể trò chuyện với nhiếp ảnh gia tại đây.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.steel, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _ConversationCard({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.snow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.pebble),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage(conversation.otherPartyAvatar),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.otherPartyName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppColors.obsidian,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: conversation.unreadCount > 0
                          ? AppColors.obsidian
                          : AppColors.steel,
                      fontWeight: conversation.unreadCount > 0
                          ? FontWeight.w600
                          : FontWeight.w400,
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
                  '${conversation.updatedAt.hour}:${conversation.updatedAt.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: AppColors.steel),
                ),
                const SizedBox(height: 8),
                if (conversation.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.ember,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      conversation.unreadCount.toString(),
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
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.obsidian : AppColors.snow,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.obsidian : AppColors.pebble,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.snow : AppColors.graphite,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  color: selected ? AppColors.snow : AppColors.ember,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
