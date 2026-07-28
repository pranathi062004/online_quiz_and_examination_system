class QuestionModel {
  final String id;
  final String categoryId;
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
  final String difficulty; // 'easy', 'medium', 'hard'

  QuestionModel({
    required this.id,
    required this.categoryId,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    required this.difficulty,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'questionText': questionText,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'explanation': explanation,
      'difficulty': difficulty,
    };
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      id: map['id'] ?? '',
      categoryId: map['categoryId'] ?? '',
      questionText: map['questionText'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctOptionIndex: map['correctOptionIndex'] ?? 0,
      explanation: map['explanation'] ?? '',
      difficulty: map['difficulty'] ?? 'medium',
    );
  }

  QuestionModel copyWith({
    String? id,
    String? categoryId,
    String? questionText,
    List<String>? options,
    int? correctOptionIndex,
    String? explanation,
    String? difficulty,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
      explanation: explanation ?? this.explanation,
      difficulty: difficulty ?? this.difficulty,
    );
  }
}
