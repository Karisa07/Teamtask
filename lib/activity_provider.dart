import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teamtask/activity_repository.dart';
import 'auth_provider.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ActivityRepository(client: client);
});

final activityFeedProvider =
    StreamProvider.autoDispose.family<List<ActivityEvent>, String>(
        (ref, boardId) {
  final repo = ref.watch(activityRepositoryProvider);
  if (boardId.isEmpty) return Stream.value(const []);
  return repo.watchBoardActivity(boardId: boardId);
});