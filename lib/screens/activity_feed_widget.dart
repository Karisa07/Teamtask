import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:teamtask/activity_provider.dart';
import 'package:teamtask/app_theme.dart';
import 'package:teamtask/activity_repository.dart';

/// Feed de actividad en tiempo real para un tablero.
/// Uso: ActivityFeed(boardId: boardId)
class ActivityFeed extends ConsumerStatefulWidget {
  final String boardId;

  const ActivityFeed({super.key, required this.boardId});

  @override
  ConsumerState<ActivityFeed> createState() => _ActivityFeedState();
}

class _ActivityFeedState extends ConsumerState<ActivityFeed> {
  @override
  bool _localeRegistered = false;

@override
void initState() {
  super.initState();

  if (!_localeRegistered) {
    timeago.setLocaleMessages('es', timeago.EsMessages());
    _localeRegistered = true;
  }
}
  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(activityFeedProvider(widget.boardId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 16,
                color: AppTheme.primaryColor,
              ),
            ),
            const Gap(8),
            const Text(
              'Actividad reciente',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const Gap(12),

        // ── Contenido ────────────────────────────────────────
        feedAsync.when(
          loading: () => const _ActivitySkeleton(),
          error: (e, _) => _ErrorCard(message: e.toString()),
          data: (events) {
            if (events.isEmpty) {
              return _EmptyFeed();
            }
            return Column(
              children: [
                for (int i = 0; i < events.length; i++)
                  _ActivityRow(
                    event: events[i],
                    isLast: i == events.length - 1,
                  ),
              ],
            ).animate().fadeIn(duration: 250.ms);
                      },
                    ),
                  ],
                );
  }
}

// ── Fila de evento ────────────────────────────────────────

class _ActivityRow extends StatelessWidget {
  final ActivityEvent event;
  final bool isLast;

  const _ActivityRow({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 32,
          child: Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    event.emoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 1.5,
                  height: 42,        // altura fija en lugar de Expanded
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: Colors.grey.shade200,
                ),
            ],
          ),
        ),
        const Gap(10),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(6),
                Text(
                  event.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(3),
                Text(
                  timeago.format(event.createdAt, locale: 'es'),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Estados vacío / error / skeleton ─────────────────────

class _EmptyFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        'Aún no hay actividad en este tablero.',
        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.2)),
      ),
      child: Text(
        'Error cargando actividad',
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      ),
    );
  }
}

class _ActivitySkeleton extends StatelessWidget {
  const _ActivitySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
  children: List.generate(
    3,
    (i) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  color: Colors.grey.shade200,
                ),
                const Gap(6),
                Container(
                  height: 10,
                  width: 80,
                  color: Colors.grey.shade100,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);
  }
}