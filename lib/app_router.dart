import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teamtask/auth_provider.dart';
import 'package:teamtask/screens/login_page.dart';
import 'package:teamtask/screens/register_page.dart';
import 'package:teamtask/screens/boards_list_page.dart';
import 'package:teamtask/screens/board_detail_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<bool>(
    ref.read(authStateProvider).valueOrNull != null,
  );

  ref.listen(authStateProvider, (_, next) {
    authNotifier.value = next.valueOrNull != null;
  });

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isLoggedIn = authNotifier.value;
      final onAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

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
          final boardName = state.extra as String? ?? 'Tablero';
          return BoardDetailPage(
            boardId: boardId,
            boardName: boardName,
          );
        },
      ),
    ],
  );
});