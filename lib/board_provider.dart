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

// ── Lista de tareas con override local para deletes optimistas ────────────────
//
// Este provider mantiene un Set de IDs eliminados localmente.
// Cuando el usuario elimina una tarea, el ID se agrega aquí inmediatamente,
// lo que hace que desaparezca de la UI sin esperar al stream de Supabase.
// Cuando el stream re-emite sin esa tarea (porque el DELETE ya se aplicó),
// el Set se limpia solo porque esa ID ya no existe en los datos.

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

  /// Elimina una tarea con optimistic update:
  /// la quita de la UI inmediatamente y luego hace el DELETE en Supabase.
  Future<void> deleteTask(String taskId) async {
    // 1. Quitar de la UI de inmediato (optimistic)
    _ref.read(_deletedTaskIdsProvider(_boardId).notifier).update(
          (ids) => {...ids, taskId},
        );

    try {
      // 2. Borrar en la BD
      await _repo.deleteTask(taskId);
      _ref.invalidate(boardsProvider);
    } catch (e) {
      // 3. Si falla, revertir el optimistic update
      _ref.read(_deletedTaskIdsProvider(_boardId).notifier).update(
            (ids) => ids.where((id) => id != taskId).toSet(),
          );
      rethrow;
    }
  }
}