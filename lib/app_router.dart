import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teamtask/auth_provider.dart';
import 'package:teamtask/screens/login_page.dart';
import 'package:teamtask/screens/register_page.dart';
import 'package:teamtask/screens/boards_list_page.dart';
import 'package:teamtask/screens/board_detail_page.dart';
import 'package:teamtask/screens/profile_page.dart';
import 'package:teamtask/screens/statistics_page.dart';


final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthNotifier();

  ref.listen(authStateProvider, (_, next) {
    authNotifier.value = next.valueOrNull != null;
  });

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authNotifier,
      redirect: (context, state) {
      // Si llega el callback OAuth con scheme custom, no hagas nada con rutas.
      // Deja que Supabase procese el URI y que el provider de auth gobierne la navegación.
      final loc = state.matchedLocation;
      if (loc.contains('login-callback') || loc.startsWith('io.supabase.teamtask://')) {
        return '/login';
      }

      final authState = ref.read(authStateProvider);

      if (authState.isLoading) return null;

      final isLoggedIn = authState.valueOrNull != null;
      final onAuth = loc == '/login' || loc == '/register';

      if (!isLoggedIn && !onAuth) return '/login';
      if (isLoggedIn && onAuth) return '/boards';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterPage(),
      ),
      GoRoute(
        path: '/boards',
        builder: (_, __) => const BoardsListPage(),
      ),
      GoRoute(
        path: '/boards/:boardId',
        builder: (_, state) {
          final boardId = state.pathParameters['boardId']!;

          // Extra puede venir como String (boardName) o como Map (focusTaskId)
          String boardName = 'Tablero';
          String? focusTaskId;

          final extra = state.extra;
          if (extra is String) {
            boardName = extra;
          } else if (extra is Map) {
            boardName = (extra['boardName'] as String?) ?? 'Tablero';
            focusTaskId = extra['focusTaskId'] as String?;
          }

          return BoardDetailPage(
            boardId: boardId,
            boardName: boardName,
            focusTaskId: focusTaskId,
          );
        },
      ),
      GoRoute(
        path: '/boards/:boardId/stats',
        builder: (_, state) {
          final boardId = state.pathParameters['boardId']!;
          final boardName = state.extra as String? ?? 'Tablero';
          return StatisticsPage(boardId: boardId, boardName: boardName);
        },
      ),

      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfilePage(),
      ),
    ],
  );
});


class _AuthNotifier extends ChangeNotifier {
  bool _value = false;

  bool get value => _value;

  set value(bool newValue) {
    if (_value != newValue) {
      _value = newValue;
      notifyListeners();
    }
  }
}