import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_state.dart';
import 'core/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/calls/calls_list_screen.dart';
import 'screens/planner/planner_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: const SekurerApp(),
    ),
  );
}

class SekurerApp extends StatelessWidget {
  const SekurerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sekurer',
      theme: buildAppTheme(),
      home: Consumer<AppState>(
        builder: (_, state, __) {
          if (state.loading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return state.token == null ? const LoginScreen() : const HomeScreen();
        },
      ),
      routes: {'/register': (_) => const RegisterScreen()},
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [const CallsListScreen(), const PlannerScreen()];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sekurer'),
        actions: [
          IconButton(
            onPressed: () => context.read<AppState>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: screens[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.call), label: 'Звонки'),
          NavigationDestination(
            icon: Icon(Icons.event_note),
            label: 'Планировщик',
          ),
        ],
      ),
    );
  }
}
