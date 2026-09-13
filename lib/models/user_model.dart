class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role;
  final bool isCompleted;
  final DateTime? currentTaskStartedAt;
  final int totalCompletedTasks;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.isCompleted = false,
    this.currentTaskStartedAt,
    this.totalCompletedTasks = 0,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'delivery_man',
      isCompleted: data['isCompleted'] ?? false,
      currentTaskStartedAt: data['currentTaskStartedAt'] != null
          ? (data['currentTaskStartedAt'] as dynamic).toDate()
          : null,
      totalCompletedTasks: data['totalCompletedTasks'] ?? 0,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as dynamic).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'isCompleted': isCompleted,
      'currentTaskStartedAt': currentTaskStartedAt,
      'totalCompletedTasks': totalCompletedTasks,
      'createdAt': createdAt,
    };
  }
}
