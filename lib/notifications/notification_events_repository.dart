import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationEventRepository {
  NotificationEventRepository({required this.client});

  final SupabaseClient client;

  /// Devuelve los eventos más recientes para un usuario.
  ///
  /// Nota: asumimos que `notification_events.title/body` contienen el texto.
  Future<List<Map<String, dynamic>>> fetchRecentForUser({
    required String userId,
    int limit = 20,
  }) async {
    final res = await client
        .from('notification_events')
        .select('id, user_id, board_id, task_id, title, body, created_at, processed_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(res as List);
  }
}

