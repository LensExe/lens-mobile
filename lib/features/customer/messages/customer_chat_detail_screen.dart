import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/models.dart';
import '../../../providers/data_providers.dart';

class CustomerChatDetailScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const CustomerChatDetailScreen({super.key, required this.conversationId});

  @override
  ConsumerState<CustomerChatDetailScreen> createState() =>
      _CustomerChatDetailScreenState();
}

class _CustomerChatDetailScreenState
    extends ConsumerState<CustomerChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(conversationsProvider.notifier)
          .markRead(widget.conversationId),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(authUserProvider);
    if (user == null) return;

    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: widget.conversationId,
      senderId: user.id,
      senderRole: 'customer',
      text: text,
      timestamp: DateTime.now(),
    );

    ref.read(messagesProvider.notifier).addMessage(newMessage);
    ref
        .read(conversationsProvider.notifier)
        .updatePreview(
          conversationId: widget.conversationId,
          message: text,
          updatedAt: newMessage.timestamp,
        );

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationsProvider);
    if (conversations.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          backgroundColor: AppColors.canvas,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.obsidian),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Tin nhắn',
            style: AppTypography.titleMd(color: AppColors.obsidian),
          ),
        ),
        body: const Center(child: Text('Chưa có cuộc trò chuyện nào.')),
      );
    }
    final conversation = conversations.firstWhere(
      (c) => c.id == widget.conversationId,
      orElse: () => conversations.first,
    );

    final allMessages = ref.watch(messagesProvider);
    final chatMessages =
        allMessages
            .where((m) => m.conversationId == widget.conversationId)
            .toList()
          ..sort(
            (a, b) => b.timestamp.compareTo(a.timestamp),
          );

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(9999),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.snow,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.pebble),
                  boxShadow: const [AppTokens.surfaceShadow],
                ),
                child: const Icon(
                  LucideIcons.arrowLeft,
                  size: 18,
                  color: AppColors.obsidian,
                ),
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.pebble),
                image: DecorationImage(
                  image: NetworkImage(conversation.otherPartyAvatar),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation.otherPartyName,
                  style: AppTypography.titleMd(
                    fontSize: 15,
                    color: AppColors.obsidian,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.emerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Đang hoạt động',
                      style: AppTypography.numeric(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.steel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: chatMessages.length,
                itemBuilder: (context, index) {
                  final message = chatMessages[index];
                  return _buildMessageBubble(message, conversation);
                },
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message, Conversation conversation) {
    final isCustomer = message.senderRole == 'customer';
    final isAI = message.senderRole == 'ai';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: isCustomer
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCustomer) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.pebble),
                image: DecorationImage(
                  image: NetworkImage(conversation.otherPartyAvatar),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isCustomer
                    ? AppColors.ember
                    : (isAI ? AppColors.fog : AppColors.snow),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isCustomer ? 20 : 4),
                  bottomRight: Radius.circular(isCustomer ? 4 : 20),
                ),
                border: (!isCustomer && !isAI)
                    ? Border.all(color: AppColors.pebble)
                    : null,
                boxShadow: const [AppTokens.surfaceShadow],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAI) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.sparkles,
                          size: 13,
                          color: AppColors.ember,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Trợ lý AI Lens',
                          style: AppTypography.labelSm(
                            fontSize: 11,
                            color: AppColors.ember,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isCustomer ? AppColors.snow : AppColors.obsidian,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isCustomer) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.snow,
        border: Border(top: BorderSide(color: AppColors.pebble)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.fog,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: AppColors.pebble.withValues(alpha: 0.6)),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn trao đổi...',
                  hintStyle: AppTypography.bodySm(color: AppColors.steel),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: _sendMessage,
            borderRadius: BorderRadius.circular(9999),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.ember,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.send,
                  color: AppColors.snow,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
