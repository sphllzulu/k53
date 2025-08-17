import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Map<String, int> _dailyAttempts = {};

  User? get currentUser => _supabase.auth.currentUser;
  Stream<User?> get authStateChanges =>
      _supabase.auth.onAuthStateChange.map((event) => event.session?.user);

  int getRemainingAttempts(String userId) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return 3 - (_dailyAttempts['$userId-$today'] ?? 0); // 3 attempts per day
  }

  void _incrementAttempt(String userId) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    _dailyAttempts.update(
      '$userId-$today',
      (value) => value + 1,
      ifAbsent: () => 1,
    );
    notifyListeners();
  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return response.user;
    } on AuthException catch (e) {
      throw _authErrorToMessage(e);
    } catch (e) {
      throw 'An unexpected error occurred';
    }
  }

  Future<User?> registerWithEmailAndPassword(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      notifyListeners();
      return response.user;
    } on AuthException catch (e) {
      throw _authErrorToMessage(e);
    } catch (e) {
      throw 'An unexpected error occurred';
    }
  }

  String _authErrorToMessage(AuthException e) {
    switch (e.message) {
      case 'Invalid login credentials':
        return 'Invalid email or password';
      case 'Email not confirmed':
        return 'Please verify your email first';
      case 'Email rate limit exceeded':
        return 'Too many attempts, please try again later';
      default:
        return e.message;
    }
  }

  Future signOut() async {
    try {
      await _supabase.auth.signOut();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      return null;
    }
  }
}