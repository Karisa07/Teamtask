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

  @override
  void initState() {
    super.initState();

    _isLoggedIn =
        Supabase.instance.client.auth.currentSession != null;
    debugPrint('🔴 AuthGate init - sesión: $_isLoggedIn');

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      debugPrint(
          '🔴 AuthState cambió: ${data.event} - sesión: ${data.session?.user.email}');
      if (mounted) {
        setState(() {
          _isLoggedIn = data.session != null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn) {
      return const BoardsListPage();
    }
    return const LoginPage();
  }
}