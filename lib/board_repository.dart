import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamtask/constants/supabase_constants.dart';

class Board {
  final String id;
  final String name;
  final String? description;
  final String emoji;
  final String createdBy;
  final DateTime createdAt;
  final int taskCount;
  final int completedCount;
  final String? inviteCode; // ← nuevo

  Board({
    required this.id,
    required this.name,
    this.description,
    required this.emoji,
    required this.createdBy,
    required this.createdAt,
    this.taskCount = 0,
    this.completedCount = 0,
    this.inviteCode, // ← nuevo
  });

  double get completionPercentage =>
      taskCount == 0 ? 0 : completedCount / taskCount;

  factory Board.fromJson(Map<String, dynamic> json) {
    return Board(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      emoji: json['emoji'] ?? '📋',
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      taskCount: (json['task_count'] ?? 0) as int,
      completedCount: (json['completed_count'] ?? 0) as int,
      inviteCode: json['invite_code'], // ← nuevo
    );
  }
}

class Task {
  final String id;
  final String boardId;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? completedAt;

  /// Usuario asignado (solo 1). Null si no está asignada.
  final String? assignedUserId;

  Task({
    required this.id,
    required this.boardId,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    required this.createdBy,
    required this.createdAt,
    this.completedAt,
    this.assignedUserId,
  });

  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';
  bool get isPending => status == 'pending';

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      boardId: json['board_id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      priority: json['priority'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      assignedUserId: json['assigned_user_id']?.toString(),
    );
  }
}


class BoardStats {
  final int total;
  final int pending;
  final int inProgress;
  final int completed;
  final double percentage;

  const BoardStats({
    required this.total,
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.percentage,
  });

  factory BoardStats.fromJson(Map<String, dynamic> json) {
    return BoardStats(
      total: (json['total'] ?? 0) as int,
      pending: (json['pending'] ?? 0) as int,
      inProgress: (json['in_progress'] ?? json['inProgress'] ?? 0) as int,
      completed: (json['completed'] ?? 0) as int,
      percentage: (json['percentage'] ?? 0.0) is double
          ? (json['percentage'] as double)
          : ((json['percentage'] ?? 0.0) as num).toDouble(),
    );
  }
}

class BoardRepository {
  BoardRepository(this.client);        // ← client público, no client
  final SupabaseClient client;

Future<void> logActivity({
  required String boardId,
  String? taskId,
  String? taskTitle,
  required String eventType,
  required String actorUserId,
  required String actorName,
  String? targetUserName,
}) async {
  debugPrint('[logActivity] eventType=$eventType actorName=$actorName taskTitle=$taskTitle');
  try {
    await client.from('activity_log').insert({
      'board_id': boardId,
      'task_id': taskId,
      'task_title': taskTitle,
      'event_type': eventType,
      'actor_user_id': actorUserId,
      'actor_name': actorName,
      'target_user_name': targetUserName,
    });
    debugPrint('[logActivity] ✅ insertado');
  } catch (e) {
    debugPrint('[logActivity] ❌ error: $e');
  }
}


  // ── Tableros ─────────────────────────────────────────

  Future<List<Board>> getBoards(String userId) async {
    // Tableros propios
    final ownedResponse = await client
        .from('boards')
        .select('*')
        .eq('created_by', userId)
        .order('created_at', ascending: false);

    // Tableros donde es miembro
    final memberResponse = await client
        .from('board_members')
        .select('board_id, boards(*)')
        .eq('user_id', userId);

    // IDs de tableros propios para no duplicar
    final ownedIds = (ownedResponse as List).map((b) => b['id']).toSet();

    // Combinar: propios + miembro (sin duplicados)
    final allJsons = [
      ...ownedResponse,
      ...(memberResponse as List)
          .map((m) => m['boards'])
          .where((b) => b != null && !ownedIds.contains(b['id'])),
    ];

    final boards = <Board>[];
    for (final json in allJsons) {
      final tasksResponse = await client
          .from('tasks')
          .select('id')
          .eq('board_id', json['id']);

      final completedResponse = await client
          .from('tasks')
          .select('id')
          .eq('board_id', json['id'])
          .eq('status', 'completed');

      boards.add(Board(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        emoji: json['emoji'] ?? '📋',
        createdBy: json['created_by'],
        createdAt: DateTime.parse(json['created_at']),
        taskCount: (tasksResponse as List).length,
        completedCount: (completedResponse as List).length,
        inviteCode: json['invite_code'],
      ));
    }

    return boards;
  }

  Future<BoardStats> getBoardStats(String boardId) async {
    final res = await client
        .rpc('get_board_stats', params: {'board_uuid': boardId});

    // Supabase rpc returns a List of rows for table returns
    final row = (res as List).isNotEmpty
        ? (res as List).first as Map<String, dynamic>
        : <String, dynamic>{};

    return BoardStats.fromJson(row);
  }

  Future<Board> createBoard({
  required String name,
  String? description,
  required String emoji,
  required String userId,
}) async {
  final inviteCode = _generateCode();

  final response = await client
      .from(SupabaseConstants.boardsTable)
      .insert({
        'name': name,
        'description': description,
        'emoji': emoji,
        'created_by': userId,
        'invite_code': inviteCode,
      })
      .select()
      .single();

  final board = Board.fromJson(response);

  // Inserta al creador como miembro del tablero
  await client
      .from('board_members')
      .insert({
        'board_id': board.id,
        'user_id': userId,
      });

  return board;
}

  // ── Invitaciones ─────────────────────────────────────

  // Unirse a un tablero con código
  Future<Board> joinBoardByCode({
    required String code,
    required String userId,
  }) async {
    // Buscar tablero por código
    final boardResponse = await client
        .from('boards')
        .select('*')
        .eq('invite_code', code.toUpperCase().trim())
        .maybeSingle();

    if (boardResponse == null) {
      throw Exception('Código de invitación inválido');
    }

    final boardId = boardResponse['id'] as String;

    // Verificar que no sea el dueño
    if (boardResponse['created_by'] == userId) {
      throw Exception('Ya eres el dueño de este tablero');
    }

    // Verificar que no sea ya miembro
    final existing = await client
        .from('board_members')
        .select('id')
        .eq('board_id', boardId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('Ya eres miembro de este tablero');
    }

    // Insertar miembro
    await client.from('board_members').insert({
      'board_id': boardId,
      'user_id': userId,
    });

    return Board.fromJson(boardResponse);
  }

  // Obtener código de invitación de un tablero
  Future<String?> getInviteCode(String boardId) async {
    final response = await client
        .from('boards')
        .select('invite_code')
        .eq('id', boardId)
        .single();
    return response['invite_code'] as String?;
  }

  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = DateTime.now().millisecondsSinceEpoch;
    var code = '';
    var seed = rand;
    for (int i = 0; i < 6; i++) {
      code += chars[seed % chars.length];
      seed = seed ~/ chars.length + i * 7;
    }
    return code;
  }

  // ── Tareas ───────────────────────────────────────────

  Future<List<Task>> getTasks(String boardId) async {
    final response = await client
        .from(SupabaseConstants.tasksTable)
        .select('*')
        .eq('board_id', boardId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Task.fromJson(json)).toList();
  }

  Future<Task> createTask({
  required String boardId,
  required String title,
  String? description,
  required String priority,
  required String userId,
}) async {
  final response = await client
      .from(SupabaseConstants.tasksTable)
      .insert({
        'board_id': boardId,
        'title': title,
        'description': description,
        'priority': priority,
        'created_by': userId,
      })
      .select()
      .single();

  return Task.fromJson(response);
}

  /// Lista miembros del tablero.
 Future<List<Map<String, dynamic>>> fetchBoardMembers(String boardId) async {
  final members = await client
      .from('board_members')
      .select('user_id')
      .eq('board_id', boardId);

  final result = <Map<String, dynamic>>[];

  for (final member in members as List) {
    final userId = member['user_id'] as String;

    final profile = await client
        .from('profiles')
        .select('id, full_name, email')
        .eq('id', userId)
        .maybeSingle();

    result.add({
      'user_id': userId,
      'profiles': profile,
    });
  }

  debugPrint('[fetchBoardMembers] members=$result');
  return result;
}



  Future<void> updateTaskAssignedUser({
  required String taskId,
  required String? assignedUserId,
}) async {
  await client
      .from(SupabaseConstants.tasksTable)
      .update({
        'assigned_user_id': assignedUserId,
      })
      .eq('id', taskId);
}
  Future<void> updateTaskStatus(
  String taskId,
  String newStatus,
) async {
  await client
      .from(SupabaseConstants.tasksTable)
      .update({
        'status': newStatus,
        if (newStatus == 'completed')
          'completed_at': DateTime.now().toIso8601String()
        else
          'completed_at': null,
      })
      .eq('id', taskId);
}


  Future<void> deleteTask(String taskId) async {
    await client
        .from(SupabaseConstants.tasksTable)
        .delete()
        .eq('id', taskId);
  }

  // ── Realtime ─────────────────────────────────────────

  Stream<List<Task>> watchTasks(String boardId) {
    return client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('board_id', boardId)
        .map((data) => data.map((json) => Task.fromJson(json)).toList())
        .distinct()
        .handleError((error) {
          debugPrint('🔴 Realtime error: $error');
        });
  }
  Future<String> fetchActorName(String userId) async {
  final profile = await client
      .from('profiles')
      .select('full_name, email')
      .eq('id', userId)
      .maybeSingle();
  return (profile?['full_name'] ?? profile?['email'] ?? 'Usuario').toString();
}
}