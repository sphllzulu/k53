import 'package:k53/models/question.dart';

class TestSession {
  final String userId;
  final DateTime startTime;
  final List<Question> questions;
  final Map<String, int?> userAnswers;

  TestSession({
    required this.userId,
    required this.questions,
    required this.userAnswers,
    DateTime? startTime,
  }) : startTime = startTime ?? DateTime.now();

  int get score => userAnswers.entries.fold(0, (sum, entry) {
    final question = questions.firstWhere((q) => q.id == entry.key);
    return sum + (entry.value == question.correctAnswerIndex ? 1 : 0);
  });

  double get percentage => (score / questions.length) * 100;

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'start_time': startTime.toIso8601String(),
      'score': score,
      'total_questions': questions.length,
      'category_scores': _calculateCategoryScores(),
    };
  }

  Map<String, int> _calculateCategoryScores() {
    final scores = <String, int>{};
    for (final question in questions) {
      if (userAnswers[question.id] == question.correctAnswerIndex) {
        scores.update(
          question.category,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }
    return scores;
  }
}