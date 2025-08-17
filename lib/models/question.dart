class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctAnswerIndex;
  final String category; // e.g. 'Road Signs', 'Rules', 'Controls'
  final String? imagePath; // Path to sign image if applicable

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctAnswerIndex,
    required this.category,
    this.imagePath,
  });

  factory Question.fromMap(Map<String, dynamic> data) {
    return Question(
      id: data['id'],
      text: data['text'],
      options: List<String>.from(data['options']),
      correctAnswerIndex: data['correctAnswerIndex'],
      category: data['category'],
    );
  }
}
