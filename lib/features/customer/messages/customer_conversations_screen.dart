import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/utils/vietnamese_text.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
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
    final query = foldVietnamese(_searchController.text.trim());
    final visible = conversations.where((conversation) {
      final matchesQuery =
          query.isEmpty ||
          foldVietnamese(conversation.otherPartyName).contains(query) ||
          foldVietnamese(conversation.lastMessage).contains(query);
      final matchesUnread = !_unreadOnly || conversation.unreadCount > 0;
      return matchesQuery && matchesUnread;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Tin nhắn',
          style: AppTypography.headlineMd(color: AppColors.obsidian),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.pageHorizontal,
              4,
              AppTokens.pageHorizontal,
              10,
            ),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.fog,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.pebble.withValues(alpha: 0.6),
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Tìm cuộc trò chuyện, nhiếp ảnh gia...',
                  hintStyle: AppTypography.bodySm(color: AppColors.steel),
                  prefixIcon: const Icon(
                    LucideIcons.search,
                    size: 18,
                    color: AppColors.steel,
                  ),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(
                            LucideIcons.x,
                            size: 16,
                            color: AppColors.steel,
                          ),
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.pageHorizontal,
              0,
              AppTokens.pageHorizontal,
              10,
            ),
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
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.pageHorizontal,
                      4,
                      AppTokens.pageHorizontal,
                      32,
                    ),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final conversation = visible[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.fog,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.messageSquare,
                size: 28,
                color: AppColors.steel,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              filtered
                  ? 'Không tìm thấy cuộc trò chuyện'
                  : 'Chưa có tin nhắn nào',
              textAlign: TextAlign.center,
              style: AppTypography.titleMd(color: AppColors.obsidian),
            ),
            const SizedBox(height: 8),
            Text(
              filtered ? 'Thử đổi từ khoá hoặc chọn bộ lọc Tất cả.' : 'Khi bạn đặt lịch chụp, các thông báo và trao đổi với nhiếp ảnh gia sẽ hiển thị tại đây.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm(color: AppColors.steel),
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
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.snow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.pebble),
          boxShadow: const [AppTokens.surfaceShadow],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.pebble),
                image: DecorationImage(
                  image: NetworkImage(conversation.otherPartyAvatar),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conversation.otherPartyName,
                          style: AppTypography.titleMd(
                            fontSize: 15,
                            color: AppColors.obsidian,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${conversation.updatedAt.hour}:${conversation.updatedAt.minute.toString().padLeft(2, '0')}',
                        style: AppTypography.numeric(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.steel,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              AppTypography.bodySm(
                                fontSize: 13,
                                color: conversation.unreadCount > 0
                                    ? AppColors.obsidian
                                    : AppColors.steel,
                              ).copyWith(
                                fontWeight: conversation.unreadCount > 0
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                        ),
                      ),
                      if (conversation.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 18,
                          height: 18,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.ember,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            conversation.unreadCount.toString(),
                            style: AppTypography.numeric(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.snow,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
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
      borderRadius: BorderRadius.circular(9999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: AppTokens.filterChipHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.obsidian : AppColors.fog,
          borderRadius: BorderRadius.circular(9999),
          border: selected
              ? null
              : Border.all(color: AppColors.pebble.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.labelMd(
                color: selected ? AppColors.snow : AppColors.steel,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? AppColors.ember : AppColors.mist,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$count',
                  style: AppTypography.numeric(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.steel,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
