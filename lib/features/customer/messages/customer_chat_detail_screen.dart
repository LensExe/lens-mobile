import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import 'api_customer_chat_repository.dart';
import 'customer_chat_realtime.dart';

class CustomerChatDetailScreen extends ConsumerStatefulWidget {
  const CustomerChatDetailScreen({
    super.key,
    required this.conversationId,
    this.isPhotographerId = false,
  });

  /// A photographer profile ID for a new/direct chat, or a chat channel ID.
  final String conversationId;
  final bool isPhotographerId;

  @override
  ConsumerState<CustomerChatDetailScreen> createState() =>
      _CustomerChatDetailScreenState();
}

class _CustomerChatDetailScreenState
    extends ConsumerState<CustomerChatDetailScreen> {
  final _textController = TextEditingController();
  CustomerChatRealtimeClient? _realtime;
  CustomerChatConversation? _conversation;
  String? _channelId;
  Object? _openError;
  bool _opening = true;
  bool _sending = false;
  bool _loadingOlder = false;
  bool _hasOlder = true;
  int _lastMarkedSequence = 0;
  int _markingSequence = 0;
  List<CustomerChatMessage> _olderMessages = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _realtime = ref.read(customerChatRealtimeClientProvider);
      _openConversation();
    });
  }

  @override
  void dispose() {
    final channelId = _channelId;
    if (channelId != null) _realtime?.unwatchChannel(channelId);
    _textController.dispose();
    super.dispose();
  }

  Future<void> _openConversation() async {
    try {
      if (widget.isPhotographerId) {
        final conversation = await ref
            .read(customerConversationsProvider.notifier)
            .startForPhotographer(widget.conversationId);
        if (!mounted) return;
        setState(() {
          _conversation = conversation;
          _channelId = conversation.id;
          _opening = false;
        });
        _realtime?.watchChannel(conversation.id);
      } else {
        setState(() {
          _channelId = widget.conversationId;
        });
        final conversations = await ref.read(
          customerConversationsProvider.future,
        );
        if (!mounted) return;
        setState(() {
          _conversation = conversations
              .where((item) => item.id == widget.conversationId)
              .firstOrNull;
          _opening = false;
        });
        _realtime?.watchChannel(widget.conversationId);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _openError = error;
          _opening = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final channelId = _channelId;
    final conversation =
        _conversation ??
        (channelId == null
            ? null
            : ref
                  .watch(customerConversationsProvider)
                  .asData
                  ?.value
                  .where((item) => item.id == channelId)
                  .firstOrNull);
    final messages = channelId == null
        ? null
        : ref.watch(customerChatMessagesProvider(channelId));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/customer_home/messages');
            }
          },
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.obsidian),
        ),
        title: Row(
          children: [
            _Avatar(
              name: conversation?.participantName ?? 'Nhiếp ảnh gia',
              imageUrl: conversation?.participantAvatar,
              size: 36,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation?.participantName ?? 'Tin nhắn',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelMd(color: AppColors.obsidian),
                  ),
                  Text(
                    'Nhiếp ảnh gia',
                    style: AppTypography.bodySm(
                      fontSize: 11,
                      color: AppColors.steel,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _refresh,
            icon: const Icon(LucideIcons.refreshCw, color: AppColors.obsidian),
          ),
        ],
      ),
      body: _opening
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.ember),
            )
          : _openError != null
          ? _FailureState(
              message: 'Không thể mở cuộc trò chuyện: $_openError',
              onRetry: () {
                setState(() {
                  _opening = true;
                  _openError = null;
                });
                _openConversation();
              },
            )
          : Column(
              children: [
                Expanded(
                  child: messages!.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.ember),
                    ),
                    error: (error, _) => _FailureState(
                      message: 'Không tải được tin nhắn: $error',
                      onRetry: () {
                        ref.invalidate(
                          customerChatMessagesProvider(channelId!),
                        );
                      },
                    ),
                    data: (items) {
                      final latestSequence = items.isEmpty
                          ? 0
                          : items.last.sequence;
                      if (latestSequence > _lastMarkedSequence &&
                          latestSequence > _markingSequence) {
                        _markingSequence = latestSequence;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _markRead(channelId!, latestSequence);
                        });
                      }
                      if (items.isEmpty) return const _EmptyChat();
                      final allMessages = [..._olderMessages, ...items]
                        ..sort((a, b) => a.sequence.compareTo(b.sequence));
                      final hasOlder = _olderMessages.isEmpty
                          ? items.length >= 100
                          : _hasOlder;
                      final newestFirst = allMessages.reversed.toList(
                        growable: false,
                      );
                      return RefreshIndicator(
                        color: AppColors.ember,
                        onRefresh: () async {
                          ref.invalidate(
                            customerChatMessagesProvider(channelId!),
                          );
                          await ref.read(
                            customerChatMessagesProvider(channelId).future,
                          );
                        },
                        child: ListView.builder(
                          reverse: true,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
                          itemCount: newestFirst.length + (hasOlder ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == newestFirst.length) {
                              return Center(
                                child: TextButton.icon(
                                  onPressed: _loadingOlder
                                      ? null
                                      : () => _loadOlder(channelId!, items),
                                  icon: _loadingOlder
                                      ? const SizedBox.square(
                                          dimension: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          LucideIcons.history,
                                          size: 17,
                                        ),
                                  label: Text(
                                    _loadingOlder
                                        ? 'Đang tải tin cũ…'
                                        : 'Tải tin nhắn cũ hơn',
                                  ),
                                ),
                              );
                            }
                            final message = newestFirst[index];
                            final canManage =
                                message.isMine &&
                                !message.isAi &&
                                !message.isRecalled;
                            return GestureDetector(
                              onLongPress: canManage
                                  ? () => _showMessageActions(message)
                                  : null,
                              child: _MessageBubble(
                                message: message,
                                participantName:
                                    conversation?.participantName ??
                                    'Nhiếp ảnh gia',
                                participantAvatar:
                                    conversation?.participantAvatar,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                _ChatComposer(
                  controller: _textController,
                  busy: _sending,
                  onSend: _send,
                ),
              ],
            ),
    );
  }

  Future<void> _refresh() async {
    final channelId = _channelId;
    if (channelId == null) return;
    ref.invalidate(customerChatMessagesProvider(channelId));
    ref.read(customerConversationsProvider.notifier).refresh();
  }

  Future<void> _send() async {
    final channelId = _channelId;
    final text = _textController.text.trim();
    if (channelId == null || text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _textController.clear();
    try {
      await ref
          .read(customerChatRepositoryProvider)
          .sendMessage(channelId: channelId, text: text);
      ref.invalidate(customerChatMessagesProvider(channelId));
      ref.invalidate(customerConversationsProvider);
    } catch (error) {
      if (mounted) {
        _textController.text = text;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không gửi được tin nhắn: $error'),
            backgroundColor: AppColors.crimson,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _markRead(String channelId, int sequence) async {
    try {
      await ref
          .read(customerConversationsProvider.notifier)
          .markRead(channelId, sequence);
      _lastMarkedSequence = sequence;
    } catch (_) {
      // The periodic refresh retries the server read cursor update.
    } finally {
      _markingSequence = 0;
    }
  }

  Future<void> _loadOlder(
    String channelId,
    List<CustomerChatMessage> latestMessages,
  ) async {
    if (_loadingOlder) return;
    final current = _olderMessages.isEmpty ? latestMessages : _olderMessages;
    if (current.isEmpty) return;
    final beforeSequence = current.first.sequence;
    if (beforeSequence <= 1) {
      setState(() => _hasOlder = false);
      return;
    }
    setState(() => _loadingOlder = true);
    try {
      final older = await ref
          .read(customerChatRepositoryProvider)
          .getMessages(channelId, beforeSequence: beforeSequence);
      final unique = older.where(
        (message) => message.sequence < beforeSequence,
      );
      if (mounted) {
        setState(() {
          _olderMessages = [...unique, ..._olderMessages];
          _hasOlder = older.length >= 100 && unique.isNotEmpty;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải thêm được tin cũ: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingOlder = false);
    }
  }

  Future<void> _showMessageActions(CustomerChatMessage message) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.pencil),
              title: const Text('Sửa tin nhắn'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.undo2),
              title: const Text('Thu hồi tin nhắn'),
              onTap: () => Navigator.pop(context, 'recall'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;

    if (action == 'edit') {
      final editor = TextEditingController(text: message.text);
      final updatedText = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sửa tin nhắn'),
          content: TextField(
            controller: editor,
            autofocus: true,
            minLines: 1,
            maxLines: 5,
            maxLength: 10000,
            decoration: const InputDecoration(
              hintText: 'Nhập nội dung tin nhắn',
              counterText: '',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, editor.text.trim()),
              child: const Text('Lưu'),
            ),
          ],
        ),
      );
      editor.dispose();
      if (updatedText == null || updatedText.isEmpty) return;
      try {
        await ref
            .read(customerChatRepositoryProvider)
            .editMessage(messageId: message.id, text: updatedText);
        if (mounted) {
          setState(() {
            _olderMessages = const [];
            _hasOlder = true;
          });
          ref.invalidate(customerChatMessagesProvider(message.channelId));
          ref.invalidate(customerConversationsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã cập nhật tin nhắn.')),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không sửa được tin nhắn: $error')),
          );
        }
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thu hồi tin nhắn?'),
        content: const Text('Tin nhắn sẽ được thay bằng thông báo đã thu hồi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Thu hồi'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(customerChatRepositoryProvider).recallMessage(message.id);
      if (mounted) {
        setState(() {
          _olderMessages = const [];
          _hasOlder = true;
        });
        ref.invalidate(customerChatMessagesProvider(message.channelId));
        ref.invalidate(customerConversationsProvider);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã thu hồi tin nhắn.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thu hồi được tin nhắn: $error')),
        );
      }
    }
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.participantName,
    this.participantAvatar,
  });

  final CustomerChatMessage message;
  final String participantName;
  final String? participantAvatar;

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisAlignment: mine
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!mine) ...[
              _Avatar(
                name: participantName,
                imageUrl: participantAvatar,
                size: 28,
              ),
              const SizedBox(width: 7),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.76,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: mine ? AppColors.obsidian : AppColors.snow,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(mine ? 18 : 5),
                    bottomRight: Radius.circular(mine ? 5 : 18),
                  ),
                  border: mine ? null : Border.all(color: AppColors.pebble),
                  boxShadow: const [AppTokens.surfaceShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.isAi) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.sparkles,
                            size: 13,
                            color: AppColors.ember,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Trợ lý AI',
                            style: AppTypography.labelSm(
                              color: mine ? AppColors.snow : AppColors.ember,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      message.text,
                      style:
                          AppTypography.bodySm(
                            color: mine ? AppColors.snow : AppColors.obsidian,
                          ).copyWith(
                            height: 1.4,
                            fontStyle: message.isRecalled
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                    ),
                    if (message.timestamp != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        DateFormat('HH:mm').format(message.timestamp!),
                        style: AppTypography.bodySm(
                          fontSize: 10,
                          color: mine
                              ? AppColors.snow.withValues(alpha: 0.7)
                              : AppColors.steel,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.imageUrl, required this.size});
  final String name;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final image = imageUrl?.trim();
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AppColors.fog,
        shape: BoxShape.circle,
      ),
      child: image == null || image.isEmpty
          ? Center(
              child: Text(
                initial,
                style: AppTypography.labelMd(color: AppColors.steel),
              ),
            )
          : Image.network(
              image,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  initial,
                  style: AppTypography.labelMd(color: AppColors.steel),
                ),
              ),
            ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.busy,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
    decoration: BoxDecoration(
      color: AppColors.snow,
      border: const Border(top: BorderSide(color: AppColors.pebble)),
      boxShadow: const [AppTokens.surfaceShadow],
    ),
    child: SafeArea(
      top: false,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !busy,
              maxLength: 10000,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Nhập tin nhắn...',
                counterText: '',
                filled: true,
                fillColor: AppColors.canvas,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTokens.pillRadius),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: busy ? null : onSend,
            tooltip: 'Gửi tin nhắn',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.ember,
              foregroundColor: AppColors.snow,
            ),
            icon: busy
                ? const SizedBox.square(
                    dimension: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.snow,
                    ),
                  )
                : const Icon(LucideIcons.arrowUp, size: 19),
          ),
        ],
      ),
    ),
  );
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.messageSquareText,
            size: 36,
            color: AppColors.steel,
          ),
          const SizedBox(height: 12),
          Text(
            'Bắt đầu cuộc trò chuyện',
            style: AppTypography.titleMd(color: AppColors.obsidian),
          ),
          const SizedBox(height: 6),
          Text(
            'Bạn có thể trao đổi trực tiếp với nhiếp ảnh gia tại đây.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySm(color: AppColors.steel),
          ),
        ],
      ),
    ),
  );
}

class _FailureState extends StatelessWidget {
  const _FailureState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.wifiOff, color: AppColors.steel, size: 32),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySm(color: AppColors.steel),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    ),
  );
}
