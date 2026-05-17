import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:teamtask/board_provider.dart';
import 'package:teamtask/board_repository.dart';
import 'package:teamtask/app_theme.dart';
import 'package:teamtask/screens/create_task_sheet.dart';
import 'package:go_router/go_router.dart';

class BoardDetailPage extends ConsumerWidget {
  final String boardId;
  final String boardName;

  const BoardDetailPage({
    super.key,
    required this.boardId,
    required this.boardName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksStreamProvider(boardId));
    final stats = ref.watch(boardStatsProvider(boardId));
    final tasksByStatus = ref.watch(tasksByStatusProvider(boardId));

   return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.go('/boards'),
        ),
        title: Text(boardName),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _RealtimeIndicator(isConnected: tasksAsync.hasValue),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${stats.completed} de ${stats.total} completadas',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(stats.percentage * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stats.percentage,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation(
                        AppTheme.primaryColor),
                    minHeight: 6,
                  ),
                ),
                const Gap(12),
                Row(
                  children: [
                    _StatChip(
                      label: '${stats.pending} por hacer',
                      color: Colors.grey.shade600,
                    ),
                    const Gap(8),
                    _StatChip(
                      label: '${stats.inProgress} en progreso',
                      color: AppTheme.warningColor,
                    ),
                    const Gap(8),
                    _StatChip(
                      label: '${stats.completed} listas',
                      color: AppTheme.successColor,
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: tasksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (_) => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                children: [
                  _KanbanColumn(
                    boardId: boardId,
                    status: 'pending',
                    label: 'Por hacer',
                    emoji: '⏳',
                    color: Colors.grey.shade600,
                    tasks: tasksByStatus['pending'] ?? [],
                  ),
                  const Gap(12),
                  _KanbanColumn(
                    boardId: boardId,
                    status: 'in_progress',
                    label: 'En progreso',
                    emoji: '🔄',
                    color: AppTheme.warningColor,
                    tasks: tasksByStatus['in_progress'] ?? [],
                  ),
                  const Gap(12),
                  _KanbanColumn(
                    boardId: boardId,
                    status: 'completed',
                    label: 'Completada',
                    emoji: '✅',
                    color: AppTheme.successColor,
                    tasks: tasksByStatus['completed'] ?? [],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => CreateTaskSheet(boardId: boardId),
        ),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ).animate().scale(delay: 400.ms),
    );
  }
}

class _KanbanColumn extends ConsumerWidget {
  final String boardId;
  final String status;
  final String label;
  final String emoji;
  final Color color;
  final List<Task> tasks;

  const _KanbanColumn({
    required this.boardId,
    required this.status,
    required this.label,
    required this.emoji,
    required this.color,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(emoji),
                const Gap(8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: color,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(10),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Text(
                      'Sin tareas',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const Gap(8),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _TaskCard(task: task, boardId: boardId)
                          .animate(key: ValueKey(task.id))
                          .fadeIn(duration: 300.ms)
                          .slideX(begin: 0.1, end: 0);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  final Task task;
  final String boardId;

  const _TaskCard({required this.task, required this.boardId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(taskActionsProvider(boardId));
    final priorityColor = task.priority == 'high'
        ? AppTheme.errorColor
        : task.priority == 'medium'
            ? AppTheme.warningColor
            : AppTheme.successColor;

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Eliminar tarea'),
            content: Text('¿Eliminar "${task.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: AppTheme.errorColor),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => actions.deleteTask(task.id),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showStatusOptions(context, actions),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        task.priority == 'high'
                            ? 'Alta'
                            : task.priority == 'medium'
                                ? 'Media'
                                : 'Baja',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: priorityColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        final next = task.isPending
                            ? 'in_progress'
                            : task.isInProgress
                                ? 'completed'
                                : 'pending';
                        actions.updateStatus(task.id, next);
                      },
                      child: Icon(
                        task.isCompleted
                            ? Icons.check_circle
                            : task.isInProgress
                                ? Icons.sync
                                : Icons.radio_button_unchecked,
                        size: 20,
                        color: task.isCompleted
                            ? AppTheme.successColor
                            : task.isInProgress
                                ? AppTheme.warningColor
                                : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                const Gap(10),
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: task.isCompleted ? Colors.grey.shade400 : null,
                  ),
                ),
                if (task.description != null) ...[
                  const Gap(6),
                  Text(
                    task.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStatusOptions(BuildContext context, TaskActions actions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
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
            const Gap(20),
            Text(task.title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const Gap(20),
            _StatusOption(
              emoji: '⏳',
              label: 'Por hacer',
              isSelected: task.isPending,
              onTap: () {
                Navigator.pop(ctx);
                actions.updateStatus(task.id, 'pending');
              },
            ),
            _StatusOption(
              emoji: '🔄',
              label: 'En progreso',
              isSelected: task.isInProgress,
              onTap: () {
                Navigator.pop(ctx);
                actions.updateStatus(task.id, 'in_progress');
              },
            ),
            _StatusOption(
              emoji: '✅',
              label: 'Completada',
              isSelected: task.isCompleted,
              onTap: () {
                Navigator.pop(ctx);
                actions.updateStatus(task.id, 'completed');
              },
            ),
            const Gap(8),
            // 
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: AppTheme.errorColor),
              title: const Text('Eliminar',
                  style: TextStyle(color: AppTheme.errorColor)),
              onTap: () {
                Navigator.pop(ctx);
                Future.delayed(const Duration(milliseconds: 300), () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (d) => AlertDialog(
                      title: const Text('Eliminar tarea'),
                      content: Text('¿Eliminar "${task.title}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(d, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(d, true),
                          child: const Text('Eliminar',
                              style: TextStyle(color: AppTheme.errorColor)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) actions.deleteTask(task.id);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusOption({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(emoji, style: const TextStyle(fontSize: 20)),
      title: Text(label,
          style: TextStyle(
              fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.w500)),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppTheme.primaryColor)
          : null,
      onTap: onTap,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _RealtimeIndicator extends StatefulWidget {
  final bool isConnected;
  const _RealtimeIndicator({required this.isConnected});

  @override
  State<_RealtimeIndicator> createState() => _RealtimeIndicatorState();
}

class _RealtimeIndicatorState extends State<_RealtimeIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: widget.isConnected
                  ? AppTheme.successColor
                      .withOpacity(0.5 + _controller.value * 0.5)
                  : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const Gap(6),
        Text(
          widget.isConnected ? 'En vivo' : 'Conectando...',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: widget.isConnected
                ? AppTheme.successColor
                : Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
}