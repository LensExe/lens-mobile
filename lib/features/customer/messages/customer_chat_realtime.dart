import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../../../core/network/api_config.dart';
import '../../../core/network/auth_session_store.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/session_interceptor.dart';
import '../bookings/controllers/customer_bookings_controller.dart';
import '../bookings/repositories/booking_gallery_repository.dart';
import '../payments/payment_repository.dart';
import '../../notifications/notification_repository.dart';
import '../../../providers/data_providers.dart' show authUserProvider;
import 'api_customer_chat_repository.dart';

final customerChatRealtimeClientProvider =
    Provider<CustomerChatRealtimeClient?>((ref) {
      final userId = ref.watch(authUserProvider.select((user) => user?.id));
      if (userId == null) return null;

      final client = CustomerChatRealtimeClient(
        ref: ref,
        namespace: ref
            .watch(apiConfigProvider)
            .requireNotificationSocketNamespace(),
        dio: ref.watch(dioProvider),
        sessionStore: ref.watch(authSessionStoreProvider),
      );
      ref.onDispose(client.dispose);
      client.start();
      return client;
    });

class CustomerChatRealtimeClient with WidgetsBindingObserver {
  CustomerChatRealtimeClient({
    required this.ref,
    required this.namespace,
    required this.dio,
    required this.sessionStore,
  }) {
    WidgetsBinding.instance.addObserver(this);
  }

  final Ref ref;
  final String namespace;
  final Dio dio;
  final AuthSessionStore sessionStore;
  final Set<String> _activeChannels = {};
  final Map<String, Timer> _threadTimers = {};

  socket_io.Socket? _socket;
  Timer? _conversationTimer;
  Timer? _tokenRefreshTimer;
  Future<void>? _refreshInFlight;
  bool _disposed = false;

  void start() {
    final token = sessionStore.accessToken;
    if (token == null || token.isEmpty) return;
    _connect(token);
  }

  void watchChannel(String channelId) {
    if (channelId.isEmpty || _disposed) return;
    _activeChannels.add(channelId);
    if (_socket?.connected == true) _refreshThread(channelId);
  }

  void unwatchChannel(String channelId) {
    _activeChannels.remove(channelId);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _conversationTimer?.cancel();
    _tokenRefreshTimer?.cancel();
    for (final timer in _threadTimers.values) {
      timer.cancel();
    }
    _threadTimers.clear();
    _socket?.dispose();
    _socket = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _disposed) return;
    final token = sessionStore.accessToken;
    if (token == null || token.isEmpty) return;
    final expiresAt = _jwtExpiry(token);
    if (expiresAt != null &&
        expiresAt.difference(DateTime.now()) <= const Duration(seconds: 45)) {
      unawaited(_refreshAndReconnect(token));
    } else if (_socket?.connected != true) {
      _connect(token);
    }
  }

  void _connect(String token) {
    if (_disposed || sessionStore.accessToken != token) return;
    _tokenRefreshTimer?.cancel();
    _socket?.dispose();

    final options = socket_io.OptionBuilder()
        .setPath('/api/v1/socket.io')
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .disableAutoConnect()
        .enableForceNew()
        .enableReconnection()
        .build();
    final socket = socket_io.io(namespace, options);
    _socket = socket;
    socket.on('chat.event', _onChatEvent);
    socket.on('notification', _onNotificationEvent);
    socket.onConnect((_) {
      if (_disposed || !identical(_socket, socket)) return;
      ref.invalidate(notificationInboxProvider);
      unawaited(
        ref.read(customerBookingsControllerProvider.notifier).loadBookings(),
      );
      _scheduleConversationRefresh();
      for (final channelId in _activeChannels) {
        _scheduleThreadRefresh(channelId);
      }
    });
    socket.connect();
    _scheduleTokenRefresh(token);
  }

  void _onChatEvent(dynamic value) {
    if (_disposed || value is! Map) return;
    final event = _string(value['event']);
    final payload = value['payload'];
    if (payload is! Map) {
      _scheduleConversationRefresh();
      return;
    }

    final channelId = _string(payload['channel_id']);
    _scheduleConversationRefresh();
    if (channelId.isNotEmpty) _scheduleThreadRefresh(channelId);

    final token = sessionStore.accessToken;
    final lastReadSequence = payload['last_read_seq'];
    if (event == 'READ_CURSOR' &&
        channelId.isNotEmpty &&
        token != null &&
        _string(payload['user_id']) == _subjectFromToken(token) &&
        lastReadSequence is num) {
      unawaited(
        ref
            .read(customerChatRepositoryProvider)
            .syncReadCursor(channelId, lastReadSequence.toInt()),
      );
    }
  }

  void _onNotificationEvent(dynamic value) {
    if (_disposed) return;
    ref.invalidate(notificationInboxProvider);
    if (value is! Map || _string(value['type']) != 'payment_success') return;

    unawaited(
      ref.read(customerBookingsControllerProvider.notifier).loadBookings(),
    );
    final data = value['data'];
    if (data is! Map) return;
    final bookingId = _string(data['booking_id']);
    if (bookingId.isEmpty) return;
    ref.invalidate(bookingPaidTotalProvider(bookingId));
    ref.invalidate(bookingGalleryProvider(bookingId));
  }

  void _scheduleConversationRefresh() {
    _conversationTimer?.cancel();
    _conversationTimer = Timer(const Duration(milliseconds: 750), () {
      if (_disposed) return;
      unawaited(ref.read(customerConversationsProvider.notifier).refresh());
    });
  }

  void _scheduleThreadRefresh(String channelId) {
    _threadTimers.remove(channelId)?.cancel();
    _threadTimers[channelId] = Timer(const Duration(milliseconds: 300), () {
      _threadTimers.remove(channelId);
      if (!_disposed) _refreshThread(channelId);
    });
  }

  void _refreshThread(String channelId) {
    ref.invalidate(customerChatMessagesProvider(channelId));
  }

  void _scheduleTokenRefresh(String token) {
    _tokenRefreshTimer?.cancel();
    final expiresAt = _jwtExpiry(token);
    if (expiresAt == null) return;
    final delay =
        expiresAt.difference(DateTime.now()) - const Duration(seconds: 45);
    _tokenRefreshTimer = Timer(
      delay.isNegative ? Duration.zero : delay,
      () => unawaited(_refreshAndReconnect(token)),
    );
  }

  Future<void> _refreshAndReconnect(String currentToken) {
    final pending = _refreshInFlight;
    if (pending != null) return pending;
    final operation = _performTokenRefresh(currentToken);
    _refreshInFlight = operation;
    return operation.whenComplete(() => _refreshInFlight = null);
  }

  Future<void> _performTokenRefresh(String currentToken) async {
    if (_disposed) return;
    final latestToken = sessionStore.accessToken;
    if (latestToken == null || latestToken.isEmpty) return;
    if (latestToken != currentToken) {
      _connect(latestToken);
      return;
    }

    try {
      final interceptor = dio.interceptors
          .whereType<SessionInterceptor>()
          .first;
      final nextToken = await interceptor.refreshAccessToken();
      if (nextToken == null || nextToken.isEmpty) {
        await sessionStore.expire();
        _disconnect();
        return;
      }
      _connect(nextToken);
    } on DioException catch (error) {
      if (const [400, 401, 403].contains(error.response?.statusCode)) {
        await sessionStore.expire();
        _disconnect();
      } else {
        _retryTokenRefresh(currentToken);
      }
    } on Object {
      _retryTokenRefresh(currentToken);
    }
  }

  void _retryTokenRefresh(String token) {
    if (_disposed || sessionStore.accessToken != token) return;
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = Timer(
      const Duration(seconds: 15),
      () => unawaited(_refreshAndReconnect(token)),
    );
  }

  void _disconnect() {
    _tokenRefreshTimer?.cancel();
    _socket?.dispose();
    _socket = null;
  }
}

DateTime? _jwtExpiry(String token) {
  try {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    if (payload is! Map || payload['exp'] is! num) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      (payload['exp'] as num).toInt() * 1000,
    );
  } on Object {
    return null;
  }
}

String _subjectFromToken(String token) {
  try {
    final parts = token.split('.');
    if (parts.length < 2) return '';
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    return payload is Map ? _string(payload['sub']) : '';
  } on Object {
    return '';
  }
}

String _string(Object? value) => value?.toString() ?? '';
