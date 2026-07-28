class CategoryModel {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final String colorHex;
  final int questionCount;
  final int timeLimitMinutes;

  CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.colorHex,
    required this.questionCount,
    required this.timeLimitMinutes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': iconName,
      'colorHex': colorHex,
      'questionCount': questionCount,
      'timeLimitMinutes': timeLimitMinutes,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      iconName: map['iconName'] ?? 'help_outline',
      colorHex: map['colorHex'] ?? '#6366F1',
      questionCount: map['questionCount'] ?? 0,
      timeLimitMinutes: map['timeLimitMinutes'] ?? 10,
    );
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    String? colorHex,
    int? questionCount,
    int? timeLimitMinutes,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      questionCount: questionCount ?? this.questionCount,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
    );
  }
}
