import 'package:advmobdev_ta/app_state.dart';
import 'package:advmobdev_ta/screens/home_screen.dart';
import 'package:advmobdev_ta/screens/login_screen.dart';
import 'package:advmobdev_ta/services/local_db_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await Firebase.initializeApp();
  }
  await LocalDbService.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'Field Agent Tracker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const RootScreen(),
      ),
    );
  }
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, state, child) {
      if (state.loading) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      if (state.user == null) {
        return const LoginScreen();
      }

      return const HomeScreen();
    });
  }
}
