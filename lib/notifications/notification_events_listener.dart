import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamtask/auth_provider.dart';
import 'package:teamtask/notifications/notification_service.dart';

class NotificationEventsListener {
  NotificationEventsListener({
    required this.client,
    required this.userId,
    required this.notificationService,
  });

  final SupabaseClient client;
  final String userId;
  final NotificationService notificationService;

  StreamSubscription<dynamic>? _sub;

  /// IDs ya notificados en esta sesión para evitar duplicados.
  /// .stream() re-emite TODAS las filas cada vez que hay un cambio,
  /// por lo que sin este set mostraría la misma notificación repetida.
  final Set<String> _notifiedIds = {};

  void start() {
    if (userId.isEmpty) return;
    _sub?.cancel();

    _sub = client
        .from('notification_events')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50)
        .listen((rows) async {
      for (final row in (rows as List)) {
        final eventId = row['id']?.toString();
        if (eventId == null) continue;

        // Ya notificado en esta sesión → skip
        if (_notifiedIds.contains(eventId)) continue;

        // Ya procesado en una sesión anterior → skip
        final processedAt = row['processed_at'];
        if (processedAt != null) continue;

        final boardId = row['board_id']?.toString();
        final taskId = row['task_id']?.toString();
        final title = row['title']?.toString();
        final body = row['body']?.toString();

        if (boardId == null || taskId == null || title == null || body == null) {
          continue;
        }

        // Marcar primero para que no se duplique si el stream re-emite
        // antes de que la llamada a Supabase termine.
        _notifiedIds.add(eventId);

        await notificationService.showTaskNotification(
          boardId: boardId,
          taskId: taskId,
          title: title,
          body: body,
        );

        // Marcar como procesado en la base de datos (best-effort)
        await client.from('notification_events').update({
          'processed_at': DateTime.now().toIso8601String(),
        }).eq('id', eventId);
      }
    });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _notifiedIds.clear();
  }
}

final notificationEventsListenerProvider =
    Provider<NotificationEventsListener>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  final userId = user?.id ?? '';

  final listener = NotificationEventsListener(
    client: client,
    userId: userId,
    notificationService: notificationService,
  );

  // Iniciar automáticamente cuando el provider se crea con un userId válido.
  // Esto reemplaza el start() manual en main.dart.
  if (userId.isNotEmpty) {
    listener.start();
  }

  // Cuando el provider se destruye (logout), detener el listener.
  ref.onDispose(() => listener.stop());

  return listener;
});