import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:teamtask/constants/supabase_constants.dart';
import 'package:teamtask/app_theme.dart';
import 'package:teamtask/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );

  // Manejar deep link inicial si la app estaba cerrada
  final appLinks = AppLinks();
  final initialUri = await appLinks.getInitialLink();
  if (initialUri != null) {
    await Supabase.instance.client.auth.getSessionFromUrl(initialUri);
  }

  runApp(const ProviderScope(child: TeamTaskApp()));
}

class TeamTaskApp extends ConsumerStatefulWidget {
  const TeamTaskApp({super.key});

  @override
  ConsumerState<TeamTaskApp> createState() => _TeamTaskAppState();
}

class _TeamTaskAppState extends ConsumerState<TeamTaskApp> {
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _handleDeepLinks();
  }

  void _handleDeepLinks() {
    _appLinks.uriLinkStream.listen((uri) async {
      if (uri.scheme == 'io.supabase.teamtask') {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TeamTask',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}