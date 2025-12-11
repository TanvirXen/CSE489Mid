import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/app_state.dart';
import 'controllers/landmark_controller.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/home/home_shell.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const LandmarkApp());
}

class LandmarkApp extends StatelessWidget {
  const LandmarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => LandmarkController()),
      ],
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Bangladesh Landmarks',
            themeMode: appState.themeMode,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            home: appState.isAuthenticated
                ? const HomeShell()
                : const SignInScreen(),
          );
        },
      ),
    );
  }
}
