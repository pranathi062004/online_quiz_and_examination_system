import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config/app_config.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'services/service_locator.dart';
import 'state/auth_provider.dart';
import 'state/exam_provider.dart';
import 'state/admin_provider.dart';
import 'views/auth/login_view.dart';
import 'views/dashboard/dashboard_view.dart';
import 'core/constants/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase if useMock is disabled
  if (!AppConfig.useMock) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  
  // Setup DI locator for mock/firebase toggling
  locator.setup();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ExamProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExamiQ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    
    if (auth.isLoading && auth.user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    
    return auth.isAuthenticated ? const DashboardView() : const LoginView();
  }
}

