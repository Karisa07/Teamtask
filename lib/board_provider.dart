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

final _deletedTaskIdsProvider =
    StateProvider.autoDispose.family<Set<String>, String>(
  (ref, boardId) => {},
);

final tasksFilteredProvider =
    Provider.autoDispose.family<List<Task>, String>((ref, boardId) {
  final tasks = ref.watch(tasksStreamProvider(boardId)).valueOrNull ?? [];
  final deletedIds = ref.watch(_deletedTaskIdsProvider(boardId));
  return tasks.where((t) => !deletedIds.contains(t.id)).toList();
});

// ── Tareas agrupadas por estado ───────────────────────────

final tasksByStatusProvider =
    Provider.family<Map<String, List<Task>>, String>((ref, boardId) {
  final tasks = ref.watch(tasksFilteredProvider(boardId));
  return {
    'pending': tasks.where((t) => t.isPending).toList(),
    'in_progress': tasks.where((t) => t.isInProgress).toList(),
    'completed': tasks.where((t) => t.isCompleted).toList(),
  };
});

// ── Estadísticas del tablero ─────

final statsProvider =
    FutureProvider.family<BoardStats, String>((ref, boardId) async {
  ref.watch(tasksStreamProvider(boardId));
  final repo = ref.watch(boardRepositoryProvider);
  return repo.getBoardStats(boardId);
});

final boardMembersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, boardId) {
    return ref
        .read(boardRepositoryProvider)
        .fetchBoardMembers(boardId);
  },
);

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

  Future<String> _getActorName() async {
    try {
      return await _repo.fetchActorName(_userId);
    } catch (_) {
      return 'Usuario';
    }
  }

  Future<void> createTask({
  required String title,
  String? description,
  String priority = 'medium',
}) async {
  final task = await _repo.createTask(
    boardId: _boardId, title: title,
    description: description, priority: priority, userId: _userId,
  );
  final actorName = await _getActorName();
  await _repo.logActivity(
    boardId: _boardId, taskId: task.id,
    taskTitle: title,                    
    eventType: 'task_created',
    actorUserId: _userId, actorName: actorName,
  );
  _ref.invalidate(boardsProvider);
}

Future<void> assignTaskToUser(String taskId, String? assignedUserId, {String? taskTitle}) async {
  await _repo.updateTaskAssignedUser(taskId: taskId, assignedUserId: assignedUserId);
  final actorName = await _getActorName();
  String? targetUserName;
  if (assignedUserId != null) {
    targetUserName = await _repo.fetchActorName(assignedUserId);
  }
  await _repo.logActivity(
    boardId: _boardId, taskId: taskId,
    taskTitle: taskTitle,
    eventType: assignedUserId != null ? 'task_assigned' : 'task_unassigned',
    actorUserId: _userId, actorName: actorName,
    targetUserName: targetUserName,      
  );
  _ref.invalidate(boardsProvider);
}

Future<void> updateStatus(String taskId, String newStatus, {String? taskTitle}) async {
  await _repo.updateTaskStatus(taskId, newStatus);
  final actorName = await _getActorName();
  await _repo.logActivity(
    boardId: _boardId, taskId: taskId,
    taskTitle: taskTitle,
    eventType: newStatus == 'completed' ? 'task_completed' : 'task_status_changed',
    actorUserId: _userId, actorName: actorName,
  );
  _ref.invalidate(boardsProvider);
}

  Future<void> deleteTask(String taskId) async {
    _ref.read(_deletedTaskIdsProvider(_boardId).notifier).update(
          (ids) => {...ids, taskId},
        );
    try {
      final actorName = await _getActorName();
      await _repo.deleteTask(taskId);
      await _repo.logActivity(
        boardId: _boardId,
        taskId: taskId,
        eventType: 'task_deleted',
        actorUserId: _userId,
        actorName: actorName,
      );
      _ref.invalidate(boardsProvider);
    } catch (e) {
      _ref.read(_deletedTaskIdsProvider(_boardId).notifier).update(
            (ids) => ids.where((id) => id != taskId).toSet(),
          );
      rethrow;
    }
  }
}
