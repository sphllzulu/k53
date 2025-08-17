import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:k53/models/question.dart';
import 'package:k53/models/test_session.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> saveTestSession(TestSession session) async {
    if (kDebugMode) {
      print('=== SAVING TEST SESSION ===');
      print('User ID: ${session.userId}');
      print('Session data: ${session.toJson()}');
      print('Auth state: ${_supabase.auth.currentSession != null ? "Authenticated" : "Not authenticated"}');
      print('Current user: ${_supabase.auth.currentUser?.id}');
    }

    try {
      // Check daily attempts
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final attempts = await _supabase
          .from('test_sessions')
          .select('id')
          .eq('user_id', session.userId)
          .gte('start_time', '$today 00:00:00')
          .lte('start_time', '$today 23:59:59');
      
      if (attempts.length >= 3) {
        throw Exception('Daily attempt limit reached (3 attempts per day)');
      }

      // Save session
      final response = await _supabase
          .from('test_sessions')
          .insert(session.toJson())
          .select();

      if (kDebugMode) {
        print('=== SAVE RESPONSE ===');
        print(response);
        print('=====================');
      }

      if (response.isEmpty) {
        throw Exception('Failed to save session - empty response');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('=== SAVE ERROR ===');
        print('Error: $e');
        print('Stack trace: $stackTrace');
        print('Table exists check: ${await _checkTableExists()}');
        print('==================');
      }

      if (e.toString().contains('permission denied')) {
        throw Exception('Permission denied - check RLS policies');
      }
      rethrow;
    }
  }

  Future<bool> _checkTableExists() async {
    try {
      await _supabase.from('test_sessions').select().limit(1);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Question>> getQuestions() async {
    try {
      final response = await _supabase
          .from('questions')
          .select()
          .order('id', ascending: true);
      
      return response.map((q) => Question.fromMap({
        'id': q['id'].toString(),
        'text': q['text'].toString(),
        'options': (q['options'] as List).map((e) => e.toString()).toList(),
        'correctAnswerIndex': q['correctAnswerIndex'] ?? q['correct_answer_index'],
        'category': q['category'].toString(),
        'imagePath': q['image_path']?.toString()
      })).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading questions: $e');
      }
      rethrow;
    }
  }

  Future<int> getUserAttemptsToday(String userId, String today) async {
    final response = await _supabase
        .from('test_sessions')
        .select('id')
        .eq('user_id', userId)
        .gte('start_time', '$today 00:00:00')
        .lte('start_time', '$today 23:59:59');
    return response.length;
  }

  Stream<List<Map<String, dynamic>>> getUserTestHistory(String userId) {
    return _supabase
        .from('test_sessions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('start_time', ascending: false);
  }
}