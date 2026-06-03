import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../app_router.dart';

class TaskNotificationPayload {
  final String boardId;
  final String taskId;

  const TaskNotificationPayload({
    required this.boardId,
    required this.taskId,
  });

  static TaskNotificationPayload? tryParse(String? payload) {
    if (payload == null) return null;
    // Expected: boardId=<>&taskId=<>
    final parts = payload.split('&');
    if (parts.length != 2) return null;

    final map = <String, String>{};
    for (final p in parts) {
      final kv = p.split('=');
      if (kv.length != 2) return null;
      map[kv[0]] = kv[1];
    }

    final boardId = map['boardId'];
    final taskId = map['taskId'];
    if (boardId == null || taskId == null) return null;

    return TaskNotificationPayload(boardId: boardId, taskId: taskId);
  }

  static String encode({required String boardId, required String taskId}) {
    return 'boardId=$boardId&taskId=$taskId';
  }
}

final flutterLocalNotificationsProvider =
    Provider<FlutterLocalNotificationsPlugin>((ref) {
  return FlutterLocalNotificationsPlugin();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    plugin: ref.watch(flutterLocalNotificationsProvider),
    router: ref.read(appRouterProvider),
  );
});

class NotificationService {
  final FlutterLocalNotificationsPlugin plugin;
  final GoRouter router;

  NotificationService({
    required this.plugin,
    required this.router,
  });

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidInit);

    await plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {
        final payload = TaskNotificationPayload.tryParse(resp.payload);
        if (payload == null) return;

        // Navegación a board detail y enfoque de task.
        router.go(
          '/boards/${payload.boardId}',
          extra: <String, String>{
            'focusTaskId': payload.taskId,
          },
        );
      },
    );
  }

  Future<void> showTaskNotification({
    required String boardId,
    required String taskId,
    required String title,
    required String body,
  }) async {
    await init();

    final payload = TaskNotificationPayload.encode(boardId: boardId, taskId: taskId);

    const androidDetails = AndroidNotificationDetails(
      'task_updates',
      'Task updates',
      channelDescription: 'Notificaciones de tareas',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    await plugin.show(
      // ID estable para evitar duplicados por taskId (ajústalo si quieres).
      taskId.hashCode,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  Future<void> requestPermissionsIfNeeded() async {
    // Manejo de permisos de Android 13+ depende de la versión del plugin.
    // En esta versión, pedimos permiso a través del helper de android.
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

}

