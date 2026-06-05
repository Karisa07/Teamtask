import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../board_repository.dart';
import '../board_provider.dart';
import '../app_theme.dart';
import '../screens/assign_task_sheet.dart';

class TaskAssignedChip extends ConsumerWidget {
  final Task task;
  final String boardId;

  const TaskAssignedChip({super.key, required this.task, required this.boardId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignedUserId = task.assignedUserId;

    final label = assignedUserId == null || assignedUserId.isEmpty
        ? 'Sin asignar'
        : 'Asignado';

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => AssignTaskSheet(boardId: boardId, task: task),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.18),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person,
              size: 16,
              color: AppTheme.primaryColor,
            ),
            const Gap(6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

