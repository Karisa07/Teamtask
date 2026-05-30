import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teamtask/auth_provider.dart';
import 'package:teamtask/board_repository.dart';

final boardRepositoryProvider = Provider<BoardRepository>((ref) {
  return BoardRepository(ref.watch(supabaseClientProvider));
});

final boardsProvider = FutureProvider<List<Board>>((ref) async {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return [];
  final repo = ref.watch(boardRepositoryProvider);
  return repo.getBoards(userId);
});

final createBoardProvider = Provider<CreateBoardService>((ref) {
  return CreateBoardService(
    ref.watch(boardRepositoryProvider),
    ref.watch(currentUserProvider)?.id ?? '',
    ref,
  );
});

class CreateBoardService {
  final BoardRepository _repo;
  final String _userId;
  final Ref _ref;

  CreateBoardService(this._repo, this._userId, this._ref);

  Future<void> call({
    required String name,
    String? description,
    required String emoji,
  }) async {
    await _repo.createBoard(
      name: name,
      description: description,
      emoji: emoji,
      userId: _userId,
    );
    _ref.invalidate(boardsProvider);
  }
}

// ── Unirse a tablero ──────────────────────────────────────

final joinBoardProvider = Provider<JoinBoardService>((ref) {
  return JoinBoardService(
    ref.watch(boardRepositoryProvider),
    ref.watch(currentUserProvider)?.id ?? '',
    ref,
  );
});

class JoinBoardService {
  final BoardRepository _repo;
  final String _userId;
  final Ref _ref;

  JoinBoardService(this._repo, this._userId, this._ref);

  Future<Board> call(String code) async {
    final board = await _repo.joinBoardByCode(
      code: code,
      userId: _userId,
    );
    _ref.invalidate(boardsProvider);
    return board;
  }
}

// ── Stream realtime de tareas ─────────────────────────────

final tasksStreamProvider =
    StreamProvider.autoDispose.family<List<Task>, String>((ref, boardId) {
  final repo = ref.watch(boardRepositoryProvider);
  return repo.watchTasks(boardId);
});

// ── Tareas agrupadas por estado ───────────────────────────

final tasksByStatusProvider =
    Provider.family<Map<String, List<Task>>, String>((ref, boardId) {
  final tasks = ref.watch(tasksStreamProvider(boardId)).valueOrNull ?? [];
  return {
    'pending': tasks.where((t) => t.isPending).toList(),
    'in_progress': tasks.where((t) => t.isInProgress).toList(),
    'completed': tasks.where((t) => t.isCompleted).toList(),
  };
});

// ── Estadísticas del tablero ──────────────────────────────

class BoardStats {
  final int total;
  final int completed;
  final int inProgress;
  final int pending;
  final double percentage;

  BoardStats({
    required this.total,
    required this.completed,
    required this.inProgress,
    required this.pending,
    required this.percentage,
  });
}

final boardStatsProvider =
    Provider.family<BoardStats, String>((ref, boardId) {
  final tasks = ref.watch(tasksStreamProvider(boardId)).valueOrNull ?? [];
  final total = tasks.length;
  final completed = tasks.where((t) => t.isCompleted).length;
  final inProgress = tasks.where((t) => t.isInProgress).length;
  final pending = tasks.where((t) => t.isPending).length;
  return BoardStats(
    total: total,
    completed: completed,
    inProgress: inProgress,
    pending: pending,
    percentage: total == 0 ? 0.0 : completed / total,
  );
});

// ── Acciones sobre tareas ─────────────────────────────────

final taskActionsProvider =
    Provider.family<TaskActions, String>((ref, boardId) {
  return TaskActions(
    repo: ref.watch(boardRepositoryProvider),
    userId: ref.watch(currentUserProvider)?.id ?? '',
    boardId: boardId,
    ref: ref,
  );
});

class TaskActions {
  final BoardRepository _repo;
  final String _userId;
  final String _boardId;
  final Ref _ref;

  TaskActions({
    required BoardRepository repo,
    required String userId,
    required String boardId,
    required Ref ref,
  })  : _repo = repo,
        _userId = userId,
        _boardId = boardId,
        _ref = ref;

  Future<void> createTask({
    required String title,
    String? description,
    String priority = 'medium',
  }) async {
    await _repo.createTask(
      boardId: _boardId,
      title: title,
      description: description,
      priority: priority,
      userId: _userId,
    );
    _ref.invalidate(boardsProvider);
  }

  Future<void> updateStatus(String taskId, String newStatus) async {
    await _repo.updateTaskStatus(taskId, newStatus);
    _ref.invalidate(boardsProvider);
  }

  Future<void> deleteTask(String taskId) async {
    await _repo.deleteTask(taskId);
    _ref.invalidate(boardsProvider);
  }
}