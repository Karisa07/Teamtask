import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationEventRepository {
  NotificationEventRepository({required this.client});

  final SupabaseClient client;

  /// Devuelve solo las notificaciones NO leídas del usuario.
  Future<List<Map<String, dynamic>>> fetchRecentForUser({
    required String userId,
    int limit = 20,
  }) async {
    final res = await client
        .from('notification_events')
        .select('id, user_id, board_id, task_id, title, body, created_at, processed_at, is_read')
        .eq('user_id', userId)
        .eq('is_read', false)                          // ← solo no leídas
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(res as List);
  }

  /// Marca una notificación como leída en Supabase.
  Future<void> markAsRead(String notificationId) async {
    await client
        .from('notification_events')
        .update({'is_read': true})
        .eq('id', notificationId);
  }
}