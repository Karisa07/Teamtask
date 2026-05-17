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

  Board({
    required this.id,
    required this.name,
    this.description,
    required this.emoji,
    required this.createdBy,
    required this.createdAt,
    this.taskCount = 0,
    this.completedCount = 0,
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

  // Obtener todos los tableros del usuario
 Future<List<Board>> getBoards(String userId) async {
  final boardsResponse = await _client
      .from('boards')
      .select('*')
      .eq('created_by', userId)
      .order('created_at', ascending: false);

  final boards = boardsResponse as List;
  final result = <Board>[];

  for (final boardJson in boards) {
    final tasksResponse = await _client
        .from('tasks')
        .select('status')
        .eq('board_id', boardJson['id']);

    final tasks = tasksResponse as List;
    final taskCount = tasks.length;
    final completedCount =
        tasks.where((t) => t['status'] == 'completed').length;

    result.add(Board(
      id: boardJson['id'],
      name: boardJson['name'],
      description: boardJson['description'],
      emoji: boardJson['emoji'] ?? '📋',
      createdBy: boardJson['created_by'],
      createdAt: DateTime.parse(boardJson['created_at']),
      taskCount: taskCount,
      completedCount: completedCount,
    ));
  }

  return result;
}
  // Crear un tablero
  Future<Board> createBoard({
    required String name,
    String? description,
    required String emoji,
    required String userId,
  }) async {
    final response = await _client
        .from(SupabaseConstants.boardsTable)
        .insert({
          'name': name,
          'description': description,
          'emoji': emoji,
          'created_by': userId,
        })
        .select()
        .single();

    return Board.fromJson(response);
  }

  // Obtener tareas de un tablero
  Future<List<Task>> getTasks(String boardId) async {
    final response = await _client
        .from(SupabaseConstants.tasksTable)
        .select('*')
        .eq('board_id', boardId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Task.fromJson(json)).toList();
  }

  // Crear una tarea
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

  // Actualizar estado de una tarea
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

  // Eliminar tarea
  Future<void> deleteTask(String taskId) async {
    await _client
        .from(SupabaseConstants.tasksTable)
        .delete()
        .eq('id', taskId);
  }

  // Stream de tareas en tiempo real
  Stream<List<Task>> watchTasks(String boardId) {
  return _client
      .from('tasks')
      .stream(primaryKey: ['id'])
      .eq('board_id', boardId)
      .map((data) => data.map((json) => Task.fromJson(json)).toList());
}
}