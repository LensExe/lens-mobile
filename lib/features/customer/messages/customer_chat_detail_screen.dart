import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/models.dart';
import '../../../providers/data_providers.dart';
import '../bookings/controllers/customer_bookings_controller.dart';
import '../bookings/models/booking_model.dart' as booking_models;
import '../bookings/widgets/booking_status_pill.dart';
import '../photographer_detail/repositories/photographer_detail_repository_provider.dart';

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
  String? _threadId;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    Future.microtask(_resolveThread);
  }

  Future<void> _resolveThread() async {
    final user = ref.read(authUserProvider);
    if (user == null || user.role != 'client') return;
    try {
      final current = ref.read(conversationsProvider);
      final found = current.where(
        (conversation) =>
            conversation.id == widget.conversationId ||
            conversation.otherPartyId == widget.conversationId,
      );
      late final Conversation conversation;
      if (found.isNotEmpty) {
        conversation = found.first;
      } else {
        final profile = await ref
            .read(photographerDetailRepositoryProvider)
            .getPhotographerProfile(widget.conversationId);
        if (!mounted) return;
        conversation = ref
            .read(conversationsProvider.notifier)
            .ensureForPhotographer(
              photographerId: profile.id,
              name: profile.name,
              avatar: profile.avatarUrl,
              clientId: user.id,
            );
      }
      ref.read(conversationsProvider.notifier).markRead(conversation.id);
      if (mounted) setState(() => _threadId = conversation.id);
    } catch (e) {
      if (mounted) {
        setState(() => _loadError = 'Không thể mở cuộc trò chuyện: $e');
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _threadId == null) return;

    final user = ref.read(authUserProvider);
    if (user == null) return;

    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: _threadId!,
      senderId: user.id,
      senderRole: 'customer',
      text: text,
      timestamp: DateTime.now(),
    );

    ref.read(messagesProvider.notifier).addMessage(newMessage);
    ref
        .read(conversationsProvider.notifier)
        .updatePreview(
          conversationId: _threadId!,
          message: text,
          updatedAt: newMessage.timestamp,
        );

    _messageController.clear();
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/customer_home/messages');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tin nhắn')),
        body: Center(child: Text(_loadError!)),
      );
    }
    if (_threadId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final conversations = ref.watch(conversationsProvider);
    if (conversations.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          backgroundColor: AppColors.canvas,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.obsidian),
            onPressed: () => _handleBack(context),
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
      (c) => c.id == _threadId,
      orElse: () => conversations.first,
    );

    final allMessages = ref.watch(messagesProvider);
    final chatMessages =
        allMessages.where((m) => m.conversationId == _threadId).toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final bookings = ref.watch(customerBookingsControllerProvider).allBookings;
    final matchingBookings = bookings
        .where((booking) => booking.id == conversation.bookingId)
        .toList();
    final linkedBooking = matchingBookings.isEmpty
        ? null
        : matchingBookings.first;

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go('/customer_home/messages');
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          backgroundColor: AppColors.canvas,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Center(
              child: InkWell(
                onTap: () => _handleBack(context),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.otherPartyName,
                      style: AppTypography.titleMd(
                        fontSize: 15,
                        color: AppColors.obsidian,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: conversation.isOnline
                                ? AppColors.emerald
                                : AppColors.steel,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          conversation.isOnline
                              ? 'Đang hoạt động'
                              : 'Ngoại tuyến',
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
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(
                LucideIcons.info,
                color: AppColors.obsidian,
                size: 20,
              ),
              onPressed: () =>
                  _showConversationInfoSheet(context, conversation),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (conversation.aiAssistantEnabled)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ember.withValues(alpha: 0.08),
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.ember.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.sparkles,
                        size: 16,
                        color: AppColors.ember,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Nhiếp ảnh gia đang bật Trợ lý AI tự động phản hồi 24/7.',
                          style: AppTypography.bodySm(
                            fontSize: 12,
                            color: AppColors.obsidian,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (linkedBooking != null)
                _BookingContextBanner(
                  booking: linkedBooking,
                  onTap: () => context.push(
                    '/customer_home/bookings/${linkedBooking.id}',
                  ),
                ),
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
                border: Border.all(
                  color: AppColors.pebble.withValues(alpha: 0.6),
                ),
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
                child: Icon(LucideIcons.send, color: AppColors.snow, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConversationInfoSheet(
    BuildContext context,
    Conversation conversation,
  ) {
    final bookingsState = ref.read(customerBookingsControllerProvider);
    final sharedBookings = bookingsState.allBookings
        .where((b) => b.photographerId == conversation.otherPartyId)
        .toList();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.snow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.pebble,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
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
                        children: [
                          Flexible(
                            child: Text(
                              conversation.otherPartyName,
                              style: AppTypography.titleMd(
                                fontSize: 16,
                                color: AppColors.obsidian,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            LucideIcons.badgeCheck,
                            size: 16,
                            color: AppColors.lagoon,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Nhiếp ảnh gia chuyên nghiệp',
                        style: AppTypography.bodySm(
                          fontSize: 12,
                          color: AppColors.steel,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push(
                        '/customer_home/photographer/${conversation.otherPartyId}',
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      side: const BorderSide(color: AppColors.pebble),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Xem hồ sơ',
                      style: AppTypography.labelMd(color: AppColors.obsidian),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push(
                        '/customer_home/photographer/${conversation.otherPartyId}/book',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ember,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Đặt lịch mới',
                      style: AppTypography.labelMd(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Lịch chụp chung (${sharedBookings.length})',
              style: AppTypography.titleMd(
                fontSize: 14,
                color: AppColors.obsidian,
              ),
            ),
            const SizedBox(height: 10),
            if (sharedBookings.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Chưa có lịch chụp nào với nhiếp ảnh gia này.',
                  style: AppTypography.bodySm(color: AppColors.steel),
                ),
              )
            else
              ...sharedBookings
                  .take(2)
                  .map(
                    (b) => InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/customer_home/bookings/${b.id}');
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.fog,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.pebble.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.calendar,
                              size: 16,
                              color: AppColors.ember,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${b.style} · ${b.date}',
                                    style: AppTypography.labelMd(
                                      color: AppColors.obsidian,
                                    ),
                                  ),
                                  Text(
                                    AppTypography.formatCurrency(b.price),
                                    style: AppTypography.numeric(
                                      fontSize: 12,
                                      color: AppColors.steel,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              LucideIcons.chevronRight,
                              size: 16,
                              color: AppColors.steel,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _BookingContextBanner extends StatelessWidget {
  final booking_models.Booking booking;
  final VoidCallback onTap;

  const _BookingContextBanner({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final packageName = booking.packageSnapshot?.name;
    final secondaryLine = packageName == null || packageName.isEmpty
        ? AppTypography.formatCurrency(booking.price)
        : packageName;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Material(
        color: AppColors.snow,
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.cardRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.cardRadius),
              border: Border.all(color: AppColors.pebble),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.fog,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.calendarDays,
                    size: 17,
                    color: AppColors.obsidian,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${booking.style} · ${booking.date}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelMd(),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        secondaryLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySm(color: AppColors.steel),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                BookingStatusPill(status: booking.status, compact: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
