import 'package:entrig/entrig.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/home_screen.dart';
import 'supabase_table.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await Entrig.init(apiKey: dotenv.env['ENTRIG_API_KEY']!);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Group Chat Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    Entrig.foregroundNotifications.listen((event) {
      // Notification received while app is in the foreground
    });

    Entrig.onNotificationOpened.listen((event) async {
      if (event.type == 'group_member_joined') {
        final groupId = event.data?['group_members.group_id'] as String?;
        if (groupId == null || !mounted) return;
        final group = await SupabaseTable.groups
            .select('id, name')
            .eq('id', groupId)
            .single();
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ChatScreen(groupId: group['id'], groupName: group['name']),
          ),
        );
      } else if (event.type == 'new_group_message') {
        final group = event.data?['group_id'];
        if (group == null || !mounted) return;

        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ChatScreen(groupId: group['id'], groupName: group['name']),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final user = snapshot.data?.session?.user;
        if (user != null) {
          Entrig.register(userId: user.id);
          return const HomeScreen();
        }
        Entrig.unregister();
        return const AuthScreen();
      },
    );
  }
}
