import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teamtask/app_theme.dart';

import '../auth_provider.dart';
import '../notifications/notification_events_provider.dart';

class HomeNotificationsSection extends ConsumerWidget {
  const HomeNotificationsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';

    debugPrint('[HomeNotificationsSection] userId=$userId user=$user');

    if (userId.isEmpty) {
      debugPrint('[HomeNotificationsSection] Sin userId. No renderiza sección.');
      return const SizedBox.shrink();
    }

    final eventsAsync = ref.watch(notificationEventsNotifierProvider);

    return eventsAsync.when(
      loading: () => _shell(
        context,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (e, _) => _shell(
        context,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Text('Error cargando notificaciones: $e'),
        ),
      ),
      data: (events) {
        if (events.isEmpty) {
          return _shell(
            context,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'No tienes notificaciones nuevas.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }

        return _shell(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final e in events.take(8))
                _EventRow(notification: e),
            ],
          ),
        );
      },
    );
  }

  Widget _shell(BuildContext context, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.notifications_outlined, size: 18),
              SizedBox(width: 8),
              Text(
                'Notificaciones recientes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'En vivo: esta sección mostrará qué usuario hizo qué acción en qué tablero.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _EventRow extends ConsumerWidget {
  final Map<String, dynamic> notification;

  const _EventRow({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = (notification['title'] ?? '').toString();
    final body = (notification['body'] ?? '').toString();
    final boardId = notification['board_id'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await ref
            .read(notificationEventsNotifierProvider.notifier)
            .markAsRead(notification['id'] as String);

        if (context.mounted && boardId != null) {
          context.push(
            '/boards/$boardId',
            extra: 'Tablero',
          );
        }
      },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isNotEmpty ? title : 'Acción',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body.isNotEmpty ? body : '—',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              // Ícono indicando que se puede navegar
              if (boardId != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
            ],
          ),
        ),
      ),
    );
  }
}