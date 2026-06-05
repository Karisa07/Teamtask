import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityEvent {
  final String id;
  final String boardId;
  final String? taskId;
  final String? taskTitle;           // ← nuevo
  final String eventType;
  final String actorUserId;
  final String? actorName;
  final String? targetUserName;      // ← nuevo
  final DateTime createdAt;

  const ActivityEvent({
    required this.id,
    required this.boardId,
    this.taskId,
    this.taskTitle,
    required this.eventType,
    required this.actorUserId,
    this.actorName,
    this.targetUserName,
    required this.createdAt,
  });

  factory ActivityEvent.fromJson(Map<String, dynamic> json) {
    return ActivityEvent(
      id: json['id'].toString(),
      boardId: json['board_id'].toString(),
      taskId: json['task_id']?.toString(),
      taskTitle: json['task_title']?.toString(),
      eventType: json['event_type'].toString(),
      actorUserId: json['actor_user_id'].toString(),
      actorName: json['actor_name']?.toString(),
      targetUserName: json['target_user_name']?.toString(),
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }

  String get label {
    final actor = actorName ?? 'Alguien';
    final task = taskTitle != null ? '"$taskTitle"' : 'una tarea';
    final target = targetUserName;

    switch (eventType) {
      case 'task_created':
        return '$actor creó $task';
      case 'task_completed':
        return '$actor completó $task';
      case 'task_status_changed':
        return '$actor movió $task';
      case 'task_assigned':
        if (target != null && target != actor) {
          return '$actor asignó $task a $target';
        }
        return '$actor se asignó $task';
      case 'task_unassigned':
        return '$actor quitó la asignación de $task';
      case 'task_deleted':
        return '$actor eliminó $task';
      default:
        return '$actor realizó una acción en $task';
    }
  }

  String get emoji {
    switch (eventType) {
      case 'task_created':     return '📝';
      case 'task_completed':   return '✅';
      case 'task_status_changed': return '🔄';
      case 'task_assigned':    return '👤';
      case 'task_unassigned':  return '➖';
      case 'task_deleted':     return '🗑️';
      default:                 return '🔔';
    }
  }
}

class ActivityRepository {
  ActivityRepository({required this.client});

  final SupabaseClient client;

  Stream<List<ActivityEvent>> watchBoardActivity({
    required String boardId,
    int limit = 30,
  }) {
    return client
        .from('activity_log')
        .stream(primaryKey: const ['id'])
        .eq('board_id', boardId)
        .order('created_at', ascending: false)
        .limit(limit)
        .map((rows) => (rows as List)
            .map((e) =>
                ActivityEvent.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList());
  }
}