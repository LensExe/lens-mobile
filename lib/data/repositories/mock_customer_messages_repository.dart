import '../../domain/models/models.dart';
import '../mock_database.dart';

abstract class CustomerMessagesRepository {
  List<Conversation> getConversations(String accountId);
  List<Message> getMessages(String accountId);
  Conversation ensureForPhotographer({
    required String accountId,
    required String photographerId,
    required String name,
    required String avatar,
  });
  void markRead(String accountId, String conversationId);
  void updatePreview({
    required String accountId,
    required String conversationId,
    required String message,
    required DateTime updatedAt,
  });
  void addMessage(String accountId, Message message);
}

class MockCustomerMessagesRepository implements CustomerMessagesRepository {
  static final Map<String, List<Conversation>> _conversations = {};
  static final Map<String, List<Message>> _messages = {};

  List<Conversation> _threads(String accountId) => _conversations.putIfAbsent(
    accountId,
    () => accountId == MockDatabase.customerUser.id
        ? List.of(MockDatabase.conversations)
        : [],
  );

  List<Message> _threadMessages(String accountId) => _messages.putIfAbsent(
    accountId,
    () => accountId == MockDatabase.customerUser.id
        ? List.of(MockDatabase.messages)
        : [],
  );

  @override
  List<Conversation> getConversations(String accountId) =>
      List.unmodifiable(_threads(accountId));

  @override
  List<Message> getMessages(String accountId) =>
      List.unmodifiable(_threadMessages(accountId));

  @override
  Conversation ensureForPhotographer({
    required String accountId,
    required String photographerId,
    required String name,
    required String avatar,
  }) {
    for (final thread in _threads(accountId)) {
      if (thread.otherPartyId == photographerId) return thread;
    }
    final thread = Conversation(
      id: 'c-$accountId-$photographerId',
      bookingId: '',
      otherPartyId: photographerId,
      otherPartyName: name,
      otherPartyAvatar: avatar,
      lastMessage: '',
      unreadCount: 0,
      updatedAt: DateTime.now(),
    );
    _threads(accountId).insert(0, thread);
    return thread;
  }

  @override
  void markRead(String accountId, String conversationId) {
    final threads = _threads(accountId);
    final index = threads.indexWhere((item) => item.id == conversationId);
    if (index < 0) throw StateError('Không tìm thấy cuộc trò chuyện.');
    threads[index] = threads[index].copyWith(unreadCount: 0);
  }

  @override
  void updatePreview({
    required String accountId,
    required String conversationId,
    required String message,
    required DateTime updatedAt,
  }) {
    final threads = _threads(accountId);
    final index = threads.indexWhere((item) => item.id == conversationId);
    if (index < 0) throw StateError('Không tìm thấy cuộc trò chuyện.');
    threads[index] = threads[index].copyWith(
      lastMessage: message,
      updatedAt: updatedAt,
    );
  }

  @override
  void addMessage(String accountId, Message message) {
    if (!_threads(accountId).any((item) => item.id == message.conversationId) ||
        message.senderId != accountId) {
      throw StateError('Không thể gửi tin nhắn vào cuộc trò chuyện này.');
    }
    _threadMessages(accountId).add(message);
  }
}
