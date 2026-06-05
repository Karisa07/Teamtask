import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth_provider.dart';
import 'notification_events_repository.dart';

final notificationEventsRepositoryProvider =
    Provider<NotificationEventRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return NotificationEventRepository(client: client);
});

class NotificationEventsNotifier
    extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';
    if (userId.isEmpty) return [];

    final client = ref.watch(supabaseClientProvider);

    // Escucha el stream en tiempo real y actualiza el estado
    final sub = client
        .from('notification_events')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(20)
        .listen((rows) {
          // Solo no leídas — pero respeta eliminaciones locales optimistas
          final unread = rows
              .where((n) => n['is_read'] == false)
              .toList();
          state = AsyncData(unread);
        });

    // Cancela el stream cuando el provider se destruye
    ref.onDispose(sub.cancel);

    return [];
  }

  Future<void> markAsRead(String notificationId) async {
    // 1. Elimina localmente al instante (optimista)
    state = AsyncData(
      state.value
              ?.where((n) => n['id'] != notificationId)
              .toList() ??
          [],
    );

    // 2. Persiste en Supabase — el stream confirmará en el próximo emit
    await ref
        .read(notificationEventsRepositoryProvider)
        .markAsRead(notificationId);
  }
}

final notificationEventsNotifierProvider =
    AsyncNotifierProvider.autoDispose<NotificationEventsNotifier,
        List<Map<String, dynamic>>>(
      NotificationEventsNotifier.new,
    );