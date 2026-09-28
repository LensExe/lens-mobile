import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/models.dart';
import '../../../providers/data_providers.dart';

class CustomerChatDetailScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const CustomerChatDetailScreen({
    super.key,
    required this.conversationId,
  });

  @override
  ConsumerState<CustomerChatDetailScreen> createState() => _CustomerChatDetailScreenState();
}

class _CustomerChatDetailScreenState extends ConsumerState<CustomerChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();

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

    // In a real app, we would call a repository to save this.
    // Here we just modify the provider state directly for the mock UI.
    ref.read(messagesProvider.notifier).addMessage(newMessage);

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationsProvider);
    final conversation = conversations.firstWhere(
      (c) => c.id == widget.conversationId,
      orElse: () => conversations.first, // fallback
    );

    final allMessages = ref.watch(messagesProvider);
    final chatMessages = allMessages
        .where((m) => m.conversationId == widget.conversationId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // reversed for ListView

    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        backgroundColor: AppColors.mist,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.obsidian),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(conversation.otherPartyAvatar),
            ),
            const SizedBox(width: 12),
            Text(
              conversation.otherPartyName,
              style: const TextStyle(
                color: AppColors.obsidian,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.info, color: AppColors.obsidian),
            onPressed: () {
              // Show booking info or photographer profile
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
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
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: isCustomer ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCustomer) ...[
            CircleAvatar(
              radius: 14,
              backgroundImage: NetworkImage(conversation.otherPartyAvatar),
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
                    ? Border.all(color: AppColors.pebble, width: 1.0)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAI)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.sparkles, size: 14, color: AppColors.ember),
                        const SizedBox(width: 6),
                        Text(
                          'Trợ lý AI',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ember,
                          ),
                        ),
                      ],
                    ),
                  if (isAI) const SizedBox(height: 4),
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isCustomer ? AppColors.snow : AppColors.obsidian,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.snow,
        border: Border(top: BorderSide(color: AppColors.pebble)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Nhập tin nhắn...',
                hintStyle: const TextStyle(color: AppColors.ash),
                filled: true,
                fillColor: AppColors.mist,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.ember,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(LucideIcons.send, color: AppColors.snow, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
