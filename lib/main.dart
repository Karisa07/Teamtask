import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamtask/constants/supabase_constants.dart';
import 'package:teamtask/app_theme.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:teamtask/app_router.dart';
import 'package:teamtask/auth_provider.dart';
import 'package:teamtask/notifications/notification_events_listener.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final plugin = FlutterLocalNotificationsPlugin();

  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );

  runApp(ProviderScope(child: TeamTaskApp(notificationPlugin: plugin)));
}

class TeamTaskApp extends ConsumerStatefulWidget {
  final FlutterLocalNotificationsPlugin notificationPlugin;
  const TeamTaskApp({super.key, required this.notificationPlugin});

  @override
  ConsumerState<TeamTaskApp> createState() => _TeamTaskAppState();
}

class _TeamTaskAppState extends ConsumerState<TeamTaskApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    
    if (user != null && user.id.isNotEmpty) {
      ref.read(notificationEventsListenerProvider);
    }

    return MaterialApp.router(
      title: 'TeamTask',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}