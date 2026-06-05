import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:teamtask/board_provider.dart';
import 'package:teamtask/board_repository.dart';
import 'package:teamtask/app_theme.dart';

class AssignTaskSheet extends ConsumerWidget {
  final String boardId;
  final Task task;

  const AssignTaskSheet({super.key, required this.boardId, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(_boardMembersFutureProvider(boardId));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(16),
          Text(
            'Asignar tarea',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
          const Gap(8),
          Text(
            task.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const Gap(16),
          membersAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: $e'),
            ),
            data: (members) {
              return Column(
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: members.length,
                    separatorBuilder: (_, __) => const Gap(8),
                    itemBuilder: (context, index) {
                      final m = members[index];
                      final userId = (m['user_id'] ?? '').toString();
                      final profile = m['profiles'] as Map<String, dynamic>?;
                      final name = (profile?['full_name'] ?? profile?['email'] ?? 'Miembro')
                          .toString();
                      final isSelected = task.assignedUserId == userId;

                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isSelected
                              ? BorderSide(color: AppTheme.primaryColor.withOpacity(0.6), width: 2)
                              : BorderSide(color: Colors.transparent, width: 2),
                        ),
                        tileColor: isSelected
                            ? AppTheme.primaryColor.withOpacity(0.08)
                            : Colors.grey.shade50,
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? AppTheme.primaryColor.withOpacity(0.15)
                              : Colors.grey.shade200,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: AppTheme.primaryColor)
                            : null,
                        onTap: () async {
                          await ref
                              .read(taskActionsProvider(boardId))
                              .assignTaskToUser(task.id, userId, taskTitle: task.title);
                          if (context.mounted) Navigator.pop(context);
                        },
                      );
                    },
                  ),
                  const Gap(12),
                  ListTile(
                    leading: const Icon(Icons.cancel_outlined, color: AppTheme.errorColor),
                    title: const Text('Quitar asignación'),
                    onTap: () async {
                      await ref
                          .read(taskActionsProvider(boardId))
                          .assignTaskToUser(task.id, null, taskTitle: task.title);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

final _boardMembersFutureProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, boardId) async {
  final repo = ref.watch(boardRepositoryProvider);
  final res = await repo.fetchBoardMembers(boardId);
  return res;
});