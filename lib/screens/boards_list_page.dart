import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:teamtask/board_provider.dart';
import 'package:teamtask/board_repository.dart';
import 'package:teamtask/auth_provider.dart';
import 'package:teamtask/app_theme.dart';
import 'package:teamtask/screens/create_board_sheet.dart';

class BoardsListPage extends ConsumerWidget {
  const BoardsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardsAsync = ref.watch(boardsProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¡Hola! 👋',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        Text(
                          currentUser?.userMetadata?['full_name']
                                  ?.toString()
                                  .split(' ')
                                  .first ??
                              'Equipo',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    PopupMenuButton(
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppTheme.primaryColor,
                        child: Text(
                          (currentUser?.userMetadata?['full_name']
                                      ?.toString()
                                      .isNotEmpty ==
                                  true)
                              ? currentUser!.userMetadata!['full_name']
                                  .toString()[0]
                                  .toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.logout, size: 18),
                              Gap(8),
                              Text('Cerrar sesión'),
                            ],
                          ),
                          onTap: () =>
                              ref.read(authServiceProvider).signOut(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: boardsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: _BoardsSkeleton(),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(child: Text('Error: $e')),
              ),
              data: (boards) {
                if (boards.isEmpty) {
                  return const SliverToBoxAdapter(child: _EmptyBoards());
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final board = boards[index];
                      return BoardCard(
                        board: board,
                        onTap: () => context.go(
                          '/boards/${board.id}',
                          extra: board.name,
                        ),
                      )
                          .animate(delay: (index * 60).ms)
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.15, end: 0);
                    },
                    childCount: boards.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const CreateBoardSheet(),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Nuevo tablero',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ).animate().scale(delay: 300.ms),
    );
  }
}

// BoardCard 
class BoardCard extends StatelessWidget {
  final Board board;
  final VoidCallback onTap;

  const BoardCard({super.key, required this.board, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        board.emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  const Gap(14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          board.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (board.description != null) ...[
                          const Gap(2),
                          Text(
                            board.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const Gap(16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${board.taskCount} tareas',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  Text(
                    '${board.completedCount} completadas',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ),
              const Gap(6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: board.completionPercentage,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(
                      AppTheme.successColor),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//Empty state 
class _EmptyBoards extends StatelessWidget {
  const _EmptyBoards();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Gap(60),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.dashboard_outlined,
            size: 48,
            color: AppTheme.primaryColor,
          ),
        ),
        const Gap(24),
        const Text(
          'Sin tableros aún',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const Gap(8),
        Text(
          'Crea tu primer tablero y empieza\na colaborar con tu equipo',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }
}

//  Skeleton 
class _BoardsSkeleton extends StatelessWidget {
  const _BoardsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (i) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .shimmer(duration: 1200.ms, color: Colors.grey.shade100),
      ),
    );
  }
}