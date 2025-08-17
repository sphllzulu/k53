import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://ehfuykqahzewctkkdeik.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVoZnV5a3FhaHpld2N0a2tkZWlrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUxNzg1MzcsImV4cCI6MjA3MDc1NDUzN30.XpV6PZp4W__LjQSudBTpm3KCMUWVugsaVfnk47IHXtU',
  );

  final supabase = Supabase.instance.client;

  // Sample K53 questions
  final questions = [
    {
      'text': 'When approaching a red traffic light, you must:',
      'options': ['Slow down', 'Stop completely', 'Proceed with caution'],
      'correct_answer_index': 1,
      'category': 'Road Signs',
      'image_path': 'assets/signs/red_light.png'
    },
    {
      'text': 'The minimum following distance in good conditions is:',
      'options': ['1 second', '2 seconds', '3 seconds'],
      'correct_answer_index': 2,
      'category': 'Rules of the Road',
      'image_path': null
    },
    // Add more questions here following the same format
  ];

  // Insert questions
  try {
    await supabase.from('questions').insert(questions);
    print('Successfully loaded ${questions.length} questions');
  } catch (e) {
    print('Error loading questions: $e');
  }
}