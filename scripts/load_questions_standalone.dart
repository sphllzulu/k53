import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://ehfuykqahzewctkkdeik.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVoZnV5a3FhaHpld2N0a2tkZWlrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUxNzg1MzcsImV4cCI6MjA3MDc1NDUzN30.XpV6PZp4W__LjQSudBTpm3KCMUWVugsaVfnk47IHXtU',
  );

  final questions = [
    // Road Signs
    {
      'text': 'When approaching a red traffic light, you must:',
      'options': ['Slow down', 'Stop completely', 'Proceed with caution'],
      'correct_answer_index': 1,
      'category': 'Road Signs'
    },
    {
      'text': 'A triangular sign with red border indicates:',
      'options': ['Warning', 'Regulation', 'Information'],
      'correct_answer_index': 0,
      'category': 'Road Signs'
    },
    
    // Rules of the Road
    {
      'text': 'The minimum following distance in good conditions is:',
      'options': ['1 second', '2 seconds', '3 seconds'],
      'correct_answer_index': 2,
      'category': 'Rules of the Road'
    },
    {
      'text': 'When overtaking, you should:',
      'options': ['Use the shoulder', 'Signal and check mirrors', 'Speed up suddenly'],
      'correct_answer_index': 1,
      'category': 'Rules of the Road'
    },
    
    // Vehicle Controls
    {
      'text': 'The clutch pedal is used to:',
      'options': ['Change gears', 'Increase speed', 'Apply brakes'],
      'correct_answer_index': 0,
      'category': 'Vehicle Controls'
    },
    
    // Road Markings
    {
      'text': 'A solid white line means:',
      'options': ['You may cross if safe', 'No overtaking allowed', 'Pedestrian crossing ahead'],
      'correct_answer_index': 1,
      'category': 'Road Markings'
    }
  ];

  try {
    await client.from('questions').insert(questions);
    print('Successfully loaded ${questions.length} questions');
  } catch (e) {
    print('Error loading questions: $e');
  }
}