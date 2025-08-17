import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:k53/auth_service.dart';
import 'package:k53/services/supabase_service.dart';
import 'package:k53/screens/auth_screen.dart';
import 'package:k53/screens/home_screen.dart';

void main() async {
  print('App starting...');
  WidgetsFlutterBinding.ensureInitialized();
  print('Initializing Supabase...');
  await Supabase.initialize(
    url: 'https://ehfuykqahzewctkkdeik.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVoZnV5a3FhaHpld2N0a2tkZWlrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUxNzg1MzcsImV4cCI6MjA3MDc1NDUzN30.XpV6PZp4W__LjQSudBTpm3KCMUWVugsaVfnk47IHXtU',
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => SupabaseService()),
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
      title: 'K53 Simulation',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (_, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            return HomeScreen(userId: snapshot.data!.id);
          }
          return const AuthScreen();
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
