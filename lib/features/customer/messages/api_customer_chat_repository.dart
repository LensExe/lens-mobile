import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/auth_session_store.dart';
import '../../../core/network/dio_client.dart';

class CustomerChatConversation {
  const CustomerChatConversation({
    required this.id,
    required this.peerKeycloakId,
    required this.participantId,
    required this.participantName,
    required this.participantAvatar,
    required this.lastMessage,
    required this.lastMessageIsAi,
    required this.unreadCount,
    required this.lastSequence,
    required this.lastMessageAt,
  });

  final String id;
  final String peerKeycloakId;
  final String participantId;
  final String participantName;
  final String? participantAvatar;
  final String lastMessage;
  final bool lastMessageIsAi;
  final int unreadCount;
  final int lastSequence;
  final DateTime? lastMessageAt;
}

class CustomerChatMessage {
  const CustomerChatMessage({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.sequence,
    required this.revision,
    required this.isAi,
    required this.isMine,
    required this.isRecalled,
  });

  final String id;
  final String channelId;
  final String senderId;
  final String text;
  final DateTime? timestamp;
  final int sequence;
  final int revision;
  final bool isAi;
  final bool isMine;
  final bool isRecalled;
}

class ApiCustomerChatRepository {
  ApiCustomerChatRepository(
    this._dio,
    this._sessionStore, {
    FlutterSecureStorage? storage,
    required this.chatBaseUrl,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final Dio _dio;
  final AuthSessionStore _sessionStore;
  final FlutterSecureStorage _storage;
  final String chatBaseUrl;

  String _chatUrl(String path) => '$chatBaseUrl$path';

  static const _readCursorKey = 'lens.chat.read-cursors.v1';
  static final Random _random = Random.secure();

  Future<List<CustomerChatConversation>> getConversations() async {
    try {
      final channels = _list(
        _unwrap((await _dio.get<dynamic>(_chatUrl('channels'))).data),
      );
      final conversations = await Future.wait(
        channels.map((value) async {
          final channel = _map(value);
          final peerId = _requiredString(channel['peer_id'], 'peer_id');
          final peer = _map(
            _unwrap(
              (await _dio.get<dynamic>(
                'users/chat-peers/${Uri.encodeComponent(peerId)}',
              )).data,
            ),
          );
          return _conversationFromChannel(channel, peer);
        }),
      );
      conversations.sort((a, b) {
        final left = a.lastMessageAt?.millisecondsSinceEpoch ?? 0;
        final right = b.lastMessageAt?.millisecondsSinceEpoch ?? 0;
        return right.compareTo(left);
      });
      return conversations;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<CustomerChatConversation> startForPhotographer(
    String photographerId,
  ) async {
    try {
      final peer = _map(
        _unwrap(
          (await _dio.get<dynamic>(
            'photographers/${Uri.encodeComponent(photographerId)}/chat-peer',
          )).data,
        ),
      );
      return await _startDirect(peer);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<CustomerChatMessage>> getMessages(
    String channelId, {
    int? beforeSequence,
  }) async {
    final queryParameters = <String, dynamic>{'limit': 100};
    if (beforeSequence != null) {
      queryParameters['before_seq'] = beforeSequence;
    }
    try {
      final response = await _dio.get<dynamic>(
        _chatUrl('channels/${Uri.encodeComponent(channelId)}/messages'),
        queryParameters: queryParameters,
      );
      final messages = _list(_unwrap(response.data))
          .map((value) => _message(_map(value)))
          .toList();
      messages.sort((a, b) => a.sequence.compareTo(b.sequence));
      return messages;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<CustomerChatMessage> sendMessage({
    required String channelId,
    required String text,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        _chatUrl('channels/${Uri.encodeComponent(channelId)}/messages'),
        data: {
          'client_message_id': _uuidV4(),
          'type': 'text',
          'content': text.trim(),
        },
      );
      return _message(_map(_unwrap(response.data)));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<CustomerChatMessage> editMessage({
    required String messageId,
    required String text,
  }) async {
    try {
      final response = await _dio.patch<dynamic>(
        _chatUrl('messages/${Uri.encodeComponent(messageId)}'),
        data: {'content': text.trim()},
      );
      return _message(_map(_unwrap(response.data)));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<CustomerChatMessage> recallMessage(String messageId) async {
    try {
      final response = await _dio.post<dynamic>(
        _chatUrl('messages/${Uri.encodeComponent(messageId)}/recall'),
      );
      return _message(_map(_unwrap(response.data)));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> markRead({
    required String channelId,
    required int lastReadSequence,
  }) async {
    if (lastReadSequence < 1) return;
    try {
      await _dio.put<dynamic>(
        _chatUrl('channels/${Uri.encodeComponent(channelId)}/read-cursor'),
        data: {'last_read_seq': lastReadSequence},
      );
      await _saveReadCursor(channelId, lastReadSequence);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> syncReadCursor(String channelId, int sequence) =>
      _saveReadCursor(channelId, sequence);

  Future<CustomerChatConversation> _startDirect(
    Map<String, dynamic> peer,
  ) async {
    final peerId = _requiredString(peer['peer_id'], 'peer_id');
    final response = await _dio.post<dynamic>(
      _chatUrl('channels/direct'),
      data: {'peer_id': peerId},
    );
    return _conversationFromChannel(_map(_unwrap(response.data)), peer);
  }

  Future<CustomerChatConversation> _conversationFromChannel(
    Map<String, dynamic> channel,
    Map<String, dynamic> peer,
  ) async {
    final channelId = _requiredString(channel['id'], 'channel.id');
    final peerId = _requiredString(peer['peer_id'], 'peer.peer_id');
    final lastSequence = _int(
      channel['last_message_seq'] ?? channel['last_message_sequence'],
    );
    Map<String, dynamic>? latest;
    if (lastSequence > 0) {
      try {
        final response = await _dio.get<dynamic>(
          _chatUrl('channels/${Uri.encodeComponent(channelId)}/messages'),
          queryParameters: const {'limit': 1},
        );
        final messages = _list(_unwrap(response.data));
        if (messages.isNotEmpty) latest = _map(messages.first);
      } on DioException catch (error) {
        throw ApiException.fromDio(error);
      }
    }

    final savedCursor = await _readCursor(channelId);
    final readCursor = savedCursor ?? lastSequence;
    if (savedCursor == null) await _saveReadCursor(channelId, lastSequence);
    final unread =
        latest != null &&
            _string(latest['sender_id']) == peerId &&
            lastSequence > readCursor
        ? max(1, lastSequence - readCursor)
        : 0;
    final latestText = latest == null
        ? ''
        : _hasValue(latest['recalled_at'])
        ? 'Tin nhắn đã được thu hồi'
        : _string(latest['content']);
    final latestIsAi = _string(latest?['sender_kind']) == 'ai';

    return CustomerChatConversation(
      id: channelId,
      peerKeycloakId: peerId,
      participantId: _string(peer['profile_id']),
      participantName: _string(peer['fullname']).isEmpty
          ? 'Nhiếp ảnh gia'
          : _string(peer['fullname']),
      participantAvatar: _nullableString(peer['avatar_url']),
      lastMessage: latestIsAi && latestText.isNotEmpty
          ? 'Trợ lý AI: $latestText'
          : latestText,
      lastMessageIsAi: latestIsAi,
      unreadCount: unread,
      lastSequence: lastSequence,
      lastMessageAt: DateTime.tryParse(
        _string(
          latest?['created_at'] ??
              channel['last_message_at'] ??
              channel['updated_at'],
        ),
      )?.toLocal(),
    );
  }

  CustomerChatMessage _message(Map<String, dynamic> json) {
    final senderId = _string(json['sender_id']);
    final isRecalled = _hasValue(json['recalled_at']);
    return CustomerChatMessage(
      id: _string(json['id']),
      channelId: _string(json['channel_id']),
      senderId: senderId,
      text: isRecalled ? 'Tin nhắn đã được thu hồi' : _string(json['content']),
      timestamp: DateTime.tryParse(_string(json['created_at']))?.toLocal(),
      sequence: _int(json['seq']),
      revision: _int(json['revision'], fallback: 1),
      isAi: _string(json['sender_kind']) == 'ai',
      isMine: senderId == _subjectFromToken(_sessionStore.accessToken),
      isRecalled: isRecalled,
    );
  }

  Future<int?> _readCursor(String channelId) async {
    try {
      final raw = await _storage.read(key: _readCursorKey);
      if (raw == null) return null;
      final value = jsonDecode(raw);
      if (value is! Map) return null;
      final cursor = value[channelId];
      return cursor is num ? cursor.toInt() : int.tryParse('$cursor');
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveReadCursor(String channelId, int sequence) async {
    try {
      final raw = await _storage.read(key: _readCursorKey);
      final decoded = raw == null ? <String, dynamic>{} : jsonDecode(raw);
      final cursors = decoded is Map
          ? decoded.map((key, value) => MapEntry('$key', value))
          : <String, dynamic>{};
      final current = _int(cursors[channelId]);
      if (sequence > current) cursors[channelId] = sequence;
      await _storage.write(key: _readCursorKey, value: jsonEncode(cursors));
    } catch (_) {
      // The server read cursor still updates even when local storage is unavailable.
    }
  }
}

final customerChatRepositoryProvider = Provider<ApiCustomerChatRepository>(
  (ref) => ApiCustomerChatRepository(
    ref.watch(dioProvider),
    ref.watch(authSessionStoreProvider),
    chatBaseUrl: ref.watch(apiConfigProvider).requireChatApiBaseUrl(),
  ),
);

final customerConversationsProvider =
    AsyncNotifierProvider<
      CustomerConversationsNotifier,
      List<CustomerChatConversation>
    >(CustomerConversationsNotifier.new);

class CustomerConversationsNotifier
    extends AsyncNotifier<List<CustomerChatConversation>> {
  @override
  Future<List<CustomerChatConversation>> build() =>
      ref.read(customerChatRepositoryProvider).getConversations();

  Future<void> refresh() async {
    final previous = state;
    final refreshed = await AsyncValue.guard(
      () => ref.read(customerChatRepositoryProvider).getConversations(),
    );
    state = refreshed.hasError && previous.hasValue ? previous : refreshed;
  }

  Future<CustomerChatConversation> startForPhotographer(
    String photographerId,
  ) async {
    final conversation = await ref
        .read(customerChatRepositoryProvider)
        .startForPhotographer(photographerId);
    final current = state.asData?.value ?? const <CustomerChatConversation>[];
    state = AsyncData(_upsertCustomerConversation(current, conversation));
    return conversation;
  }

  Future<void> markRead(String channelId, int sequence) async {
    await ref
        .read(customerChatRepositoryProvider)
        .markRead(channelId: channelId, lastReadSequence: sequence);
    await refresh();
  }
}

final customerChatMessagesProvider =
    FutureProvider.family<List<CustomerChatMessage>, String>(
      (ref, channelId) =>
          ref.watch(customerChatRepositoryProvider).getMessages(channelId),
    );

List<CustomerChatConversation> _upsertCustomerConversation(
  List<CustomerChatConversation> items,
  CustomerChatConversation next,
) {
  final result = [...items];
  final index = result.indexWhere((item) => item.id == next.id);
  if (index < 0) {
    result.insert(0, next);
  } else {
    result[index] = next;
  }
  return result;
}

String _subjectFromToken(String? token) {
  if (token == null) return '';
  try {
    final parts = token.split('.');
    if (parts.length < 2) return '';
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    return payload is Map ? _string(payload['sub']) : '';
  } catch (_) {
    return '';
  }
}

String _uuidV4() {
  final bytes = List<int>.generate(
    16,
    (_) => ApiCustomerChatRepository._random.nextInt(256),
  );
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((value) => value.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, item) => MapEntry('$key', item));
  throw const ApiException('Chat API trả dữ liệu không đúng cấu trúc.');
}

List<dynamic> _list(Object? value) {
  if (value is List) return value;
  if (value is Map) {
    final payload = _map(value);
    if (payload['items'] is List) return payload['items'] as List;
  }
  throw const ApiException('Chat API trả danh sách không đúng cấu trúc.');
}

Object? _unwrap(Object? value) {
  var payload = value;
  while (payload is Map) {
    final map = _map(payload);
    if (map.containsKey('success') && map.containsKey('data')) {
      if (map['success'] != true) {
        throw const ApiException('Chat API không xác nhận yêu cầu thành công.');
      }
      payload = map['data'];
      continue;
    }
    if (map.length == 1 && map.containsKey('data')) {
      payload = map['data'];
      continue;
    }
    return map;
  }
  return payload;
}

String _requiredString(Object? value, String field) {
  final string = _string(value).trim();
  if (string.isNotEmpty) return string;
  throw ApiException('Chat API thiếu trường $field.');
}

String _string(Object? value) => value?.toString() ?? '';
String? _nullableString(Object? value) => value?.toString();
bool _hasValue(Object? value) => value != null && value.toString().isNotEmpty;
int _int(Object? value, {int fallback = 0}) => value is num
    ? value.toInt()
    : int.tryParse(value?.toString() ?? '') ?? fallback;
