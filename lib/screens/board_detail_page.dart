import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:teamtask/board_provider.dart';
import 'package:teamtask/board_repository.dart';
import 'package:teamtask/profile_provider.dart';
import 'package:teamtask/auth_provider.dart';
import 'package:teamtask/app_theme.dart';
import 'package:teamtask/screens/create_task_sheet.dart';
import 'package:teamtask/screens/activity_feed_widget.dart';
import 'package:teamtask/screens/assign_task_sheet.dart';
import 'package:teamtask/widgets/task_assigned_chip.dart';


class BoardDetailPage extends ConsumerWidget {
  final String boardId;
  final String boardName;
  final String? focusTaskId;

  const BoardDetailPage({
    super.key,
    required this.boardId,
    required this.boardName,
    this.focusTaskId,
  });

  void _showInviteCode(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(boardRepositoryProvider);
    final code = await repo.getInviteCode(boardId);
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(20),
            const Icon(Icons.group_add_outlined, size: 40, color: AppTheme.primaryColor),
            const Gap(12),
            const Text('Código de invitación',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const Gap(6),
            Text(
              'Comparte este código para que otros\nse unan al tablero',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const Gap(24),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: code ?? ''));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Código copiado al portapapeles'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2), width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      code ?? '------',
                      style: const TextStyle(
                        fontSize: 36, fontWeight: FontWeight.w900,
                        letterSpacing: 10, color: AppTheme.primaryColor,
                      ),
                    ),
                    const Gap(12),
                    const Icon(Icons.copy, color: AppTheme.primaryColor, size: 20),
                  ],
                ),
              ),
            ),
            const Gap(12),
            Text('Toca el código para copiarlo',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
            const Gap(24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Solo providers que cambian raramente
    final profileAsync = ref.watch(profileProvider);
    final currentUser = ref.watch(currentUserProvider);
    final boardsAsync = ref.watch(boardsProvider);

    final isOwner = boardsAsync.valueOrNull
            ?.firstWhere(
              (b) => b.id == boardId,
              orElse: () => Board(
                id: '', name: '', emoji: '',
                createdBy: '', createdAt: DateTime.now(),
              ),
            )
            .createdBy ==
        currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: Text(boardName),
        actions: [
          IconButton(
            tooltip: 'Ver estadísticas',
            onPressed: () => context.push('/boards/$boardId/stats', extra: boardName),
            icon: const Icon(Icons.bar_chart_rounded),
          ),
          if (isOwner)
            IconButton(
              onPressed: () => _showInviteCode(context, ref),
              icon: const Icon(Icons.group_add_outlined),
              tooltip: 'Código de invitación',
            ),
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor,
              backgroundImage: profileAsync.valueOrNull?.avatarUrl != null
                  ? NetworkImage(profileAsync.valueOrNull!.avatarUrl!)
                  : null,
              child: profileAsync.valueOrNull?.avatarUrl == null
                  ? Text(
                      (profileAsync.valueOrNull?.fullName?.isNotEmpty == true)
                          ? profileAsync.valueOrNull!.fullName![0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 13, color: Colors.white, fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
          ),
          const Gap(8),
          // _RealtimeIndicator aislado con su propio Consumer
          Consumer(
            builder: (context, ref, _) {
              final tasksAsync = ref.watch(tasksStreamProvider(boardId));
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _RealtimeIndicator(isConnected: tasksAsync.hasValue),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Barra de progreso — Consumer aislado ─────────
          Consumer(
            builder: (context, ref, _) {
              final statsAsync = ref.watch(statsProvider(boardId));
              final stats = statsAsync.valueOrNull ??
                  const BoardStats(
                    total: 0, pending: 0, inProgress: 0,
                    completed: 0, percentage: 0,
                  );
              return Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${stats.completed} de ${stats.total} completadas',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${(stats.percentage * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
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
                        valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
                        minHeight: 6,
                      ),
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        _StatChip(label: '${stats.pending} por hacer', color: Colors.grey.shade600),
                        const Gap(8),
                        _StatChip(label: '${stats.inProgress} en progreso', color: AppTheme.warningColor),
                        const Gap(8),
                        _StatChip(label: '${stats.completed} listas', color: AppTheme.successColor),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // ── Kanban + Activity ─────────────────────────────
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final tasksAsync = ref.watch(tasksStreamProvider(boardId));
                return tasksAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (_) => CustomScrollView(
                    slivers: [
                      // ── Kanban ───────────────────────────
                      SliverToBoxAdapter(
                        child: Consumer(
                          builder: (context, ref, _) {
                            final tasksByStatus = ref.watch(tasksByStatusProvider(boardId));
                            return SizedBox(
                              height: 420,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.all(16),
                                children: [
                                  _KanbanColumn(
                                    boardId: boardId,
                                    status: 'pending',
                                    label: 'Por hacer',
                                    emoji: '⏳',
                                    color: Colors.grey.shade600,
                                    focusTaskId: focusTaskId,
                                    tasks: tasksByStatus['pending'] ?? [],
                                  ),
                                  const Gap(12),
                                  _KanbanColumn(
                                    boardId: boardId,
                                    status: 'in_progress',
                                    label: 'En progreso',
                                    emoji: '🔄',
                                    color: AppTheme.warningColor,
                                    focusTaskId: focusTaskId,
                                    tasks: tasksByStatus['in_progress'] ?? [],
                                  ),
                                  const Gap(12),
                                  _KanbanColumn(
                                    boardId: boardId,
                                    status: 'completed',
                                    label: 'Completada',
                                    emoji: '✅',
                                    color: AppTheme.successColor,
                                    focusTaskId: focusTaskId,
                                    tasks: tasksByStatus['completed'] ?? [],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // ── Miembros ─────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Consumer(
  builder: (context, ref, _) {
    final membersAsync =
        ref.watch(boardMembersProvider(boardId));

    return membersAsync.when(
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
      data: (members) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Miembros del tablero',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: members.map((m) {
                final profile =
                    m['profiles'] as Map<String, dynamic>?;

                final name =
                    profile?['full_name']?.toString() ??
                    profile?['email']?.toString() ??
                    'Usuario';

                return Tooltip(
                  message: name,
                  child: CircleAvatar(
                    child: Text(
                      name[0].toUpperCase(),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  },
)
                        ),
                      ),

                      // ── Actividad ────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          child: ActivityFeed(boardId: boardId),
                        ),
                      ),
                    ],
                  ),
                );
              },
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
      ),
    );
  }
}
// ── KanbanColumn ─────────────────────────────────────────

class _KanbanColumn extends StatelessWidget {
  final String boardId;
  final String status;
  final String label;
  final String emoji;
  final Color color;
  final String? focusTaskId;
  final List<Task> tasks;

  const _KanbanColumn({
    required this.boardId,
    required this.status,
    required this.label,
    required this.emoji,
    required this.color,
    required this.tasks,
    required this.focusTaskId,
  });

  @override
  Widget build(BuildContext context) {
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
                Text(label, style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13, color: color,
                )),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
                  ),
                ),
              ],
            ),
          ),
          const Gap(10),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Text('Sin tareas',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                  )
                : ListView.separated(
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const Gap(8),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _TaskCard(
                        key: ValueKey(task.id),
                        task: task,
                        boardId: boardId,
                        focusTaskId: focusTaskId,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── TaskCard ──────────────────────────────────────────────

class _TaskCard extends ConsumerWidget {
  final Task task;
  final String boardId;
  final String? focusTaskId;

  const _TaskCard({
    super.key,
    required this.task,
    required this.boardId,
    required this.focusTaskId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(taskActionsProvider(boardId));
    final priorityColor = task.priority == 'high'
        ? AppTheme.errorColor
        : task.priority == 'medium'
            ? AppTheme.warningColor
            : AppTheme.successColor;
    final isFocused = focusTaskId != null && focusTaskId == task.id;

    return Dismissible(
      key: ValueKey('dismissible_${task.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirm = await showDialog<bool>(
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
                child: const Text('Eliminar',
                    style: TextStyle(color: AppTheme.errorColor)),
              ),
            ],
          ),
        );
        if (confirm == true) await actions.deleteTask(task.id);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        shape: isFocused
            ? RoundedRectangleBorder(
                side: const BorderSide(color: AppTheme.primaryColor, width: 2),
                borderRadius: BorderRadius.circular(16),
              )
            : RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                          fontSize: 10, fontWeight: FontWeight.w700, color: priorityColor,
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
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted ? Colors.grey.shade400 : null,
                  ),
                ),
                const Gap(6),
                TaskAssignedChip(task: task, boardId: boardId),
                if (task.description != null) ...[
                  const Gap(6),
                  Text(
                    task.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(20),
            Text(task.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Gap(20),
            _StatusOption(
              emoji: '⏳', label: 'Por hacer', isSelected: task.isPending,
              onTap: () { Navigator.pop(ctx); actions.updateStatus(task.id, 'pending'); },
            ),
            _StatusOption(
              emoji: '🔄', label: 'En progreso', isSelected: task.isInProgress,
              onTap: () { Navigator.pop(ctx); actions.updateStatus(task.id, 'in_progress'); },
            ),
            _StatusOption(
              emoji: '✅', label: 'Completada', isSelected: task.isCompleted,
              onTap: () { Navigator.pop(ctx); actions.updateStatus(task.id, 'completed'); },
            ),
            const Gap(8),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
              title: const Text('Eliminar', style: TextStyle(color: AppTheme.errorColor)),
              onTap: () async {
                Navigator.pop(ctx);
                await Future.delayed(const Duration(milliseconds: 300));
                if (!context.mounted) return;
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
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── StatusOption ──────────────────────────────────────────

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
          style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
      trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

// ── StatChip ──────────────────────────────────────────────

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
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ── RealtimeIndicator ─────────────────────────────────────

class _RealtimeIndicator extends StatelessWidget {
  final bool isConnected;

  const _RealtimeIndicator({
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isConnected
                ? AppTheme.successColor
                : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const Gap(6),
        Text(
          isConnected ? 'En vivo' : 'Conectando...',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isConnected
                ? AppTheme.successColor
                : Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
}