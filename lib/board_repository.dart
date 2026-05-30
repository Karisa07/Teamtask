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
    );
  }
}

class BoardRepository {
  final SupabaseClient _client;

  BoardRepository(this._client);

  // ── Tableros ─────────────────────────────────────────

  Future<List<Board>> getBoards(String userId) async {
    // Tableros propios
    final ownedResponse = await _client
        .from('boards')
        .select('*')
        .eq('created_by', userId)
        .order('created_at', ascending: false);

    // Tableros donde es miembro
    final memberResponse = await _client
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
      final tasksResponse = await _client
          .from('tasks')
          .select('id')
          .eq('board_id', json['id']);

      final completedResponse = await _client
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

  Future<Board> createBoard({
    required String name,
    String? description,
    required String emoji,
    required String userId,
  }) async {
    // Generar código de invitación aleatorio de 6 caracteres
    final inviteCode = _generateCode();

    final response = await _client
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

    return Board.fromJson(response);
  }

  // ── Invitaciones ─────────────────────────────────────

  // Unirse a un tablero con código
  Future<Board> joinBoardByCode({
    required String code,
    required String userId,
  }) async {
    // Buscar tablero por código
    final boardResponse = await _client
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
    final existing = await _client
        .from('board_members')
        .select('id')
        .eq('board_id', boardId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('Ya eres miembro de este tablero');
    }

    // Insertar miembro
    await _client.from('board_members').insert({
      'board_id': boardId,
      'user_id': userId,
    });

    return Board.fromJson(boardResponse);
  }

  // Obtener código de invitación de un tablero
  Future<String?> getInviteCode(String boardId) async {
    final response = await _client
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
    final response = await _client
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
    final response = await _client
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

  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    await _client
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
    await _client
        .from(SupabaseConstants.tasksTable)
        .delete()
        .eq('id', taskId);
  }

  // ── Realtime ─────────────────────────────────────────

  Stream<List<Task>> watchTasks(String boardId) {
    return _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('board_id', boardId)
        .map((data) => data.map((json) => Task.fromJson(json)).toList())
        .distinct()
        .handleError((error) {
          debugPrint('🔴 Realtime error: $error');
        });
  }
}