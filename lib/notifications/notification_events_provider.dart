import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth_provider.dart';
import 'notification_events_repository.dart';

final notificationEventsRepositoryProvider =
    Provider<NotificationEventRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return NotificationEventRepository(client: client);
});

/// StreamProvider: escucha la tabla en tiempo real via Supabase Realtime.
/// Se actualiza automáticamente cada vez que llega un evento nuevo.
final notificationEventsRecentProvider =
    StreamProvider.family<List<Map<String, dynamic>>, int>((ref, limit) {
  final user = ref.watch(currentUserProvider);
  final userId = user?.id ?? '';

  if (userId.isEmpty) {
    return Stream.value(<Map<String, dynamic>>[]);
  }

  final client = ref.watch(supabaseClientProvider);

  // .stream() de Supabase emite cada vez que hay INSERT/UPDATE/DELETE
  // en la tabla para este usuario, manteniendo la UI en tiempo real.
  return client
      .from('notification_events')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .limit(limit)
      .map((rows) => List<Map<String, dynamic>>.from(rows));
});