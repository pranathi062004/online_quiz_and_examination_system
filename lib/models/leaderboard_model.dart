class LeaderboardEntry {
  final String userId;
  final String userName;
  final String categoryName;
  final int score;
  final int timeTakenSeconds;
  final DateTime completedAt;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    required this.categoryName,
    required this.score,
    required this.timeTakenSeconds,
    required this.completedAt,
  });
}
