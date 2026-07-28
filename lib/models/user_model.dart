class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role; // 'student' or 'admin'
  final String? profilePicUrl;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.profilePicUrl,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin' || email.toLowerCase().contains('admin') || email.toLowerCase().contains('teacher');

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
      'profilePicUrl': profilePicUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      role: map['role'] ?? 'student',
      profilePicUrl: map['profilePicUrl'],
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
    );
  }
}
