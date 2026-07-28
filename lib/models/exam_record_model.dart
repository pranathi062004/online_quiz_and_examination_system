class ExamRecordModel {
  final String id;
  final String userId;
  final String userName;
  final String categoryId;
  final String categoryName;
  final int score; // Percentage score or points (we will use percentage)
  final int totalQuestions;
  final int correctAnswers;
  final int timeTakenSeconds;
  final DateTime completedAt;
  final String certificateId;

  ExamRecordModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.categoryId,
    required this.categoryName,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.timeTakenSeconds,
    required this.completedAt,
    required this.certificateId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'score': score,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'timeTakenSeconds': timeTakenSeconds,
      'completedAt': completedAt.toIso8601String(),
      'certificateId': certificateId,
    };
  }

  factory ExamRecordModel.fromMap(Map<String, dynamic> map) {
    return ExamRecordModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
      score: map['score'] ?? 0,
      totalQuestions: map['totalQuestions'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      timeTakenSeconds: map['timeTakenSeconds'] ?? 0,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : DateTime.now(),
      certificateId: map['certificateId'] ?? '',
    );
  }
}
