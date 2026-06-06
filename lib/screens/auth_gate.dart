import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamtask/screens/login_page.dart';
import 'package:teamtask/screens/boards_list_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoggedIn = false;
  late final StreamSubscription<AuthState> _authSub;
  late final StreamSubscription<Uri> _linkSub;
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();

    _isLoggedIn = Supabase.instance.client.auth.currentSession != null;

    // Escucha cambios de autenticación
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          _isLoggedIn = data.session != null;
        });
      }
    });

    // Escucha deep links entrantes (callback de OAuth)
    _linkSub = _appLinks.uriLinkStream.listen((uri) async {
      debugPrint('🔗 Deep link recibido: $uri');
      if (uri.scheme == 'io.supabase.teamtask') {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    _linkSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn) {
      return const BoardsListPage();
    }
    return const LoginPage();
  }
}