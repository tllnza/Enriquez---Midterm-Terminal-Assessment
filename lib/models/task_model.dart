import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final int? id;
  final String? remoteId;
  final String title;
  final String details;
  final bool completed;
  final bool synced;
  final bool deleted;
  final DateTime updatedAt;

  TaskModel({
    this.id,
    this.remoteId,
    required this.title,
    required this.details,
    required this.completed,
    required this.synced,
    required this.deleted,
    required this.updatedAt,
  });

  TaskModel copyWith({
    int? id,
    String? remoteId,
    String? title,
    String? details,
    bool? completed,
    bool? synced,
    bool? deleted,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      title: title ?? this.title,
      details: details ?? this.details,
      completed: completed ?? this.completed,
      synced: synced ?? this.synced,
      deleted: deleted ?? this.deleted,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TaskModel.fromMap(Map<String, Object?> map) {
    return TaskModel(
      id: map['id'] as int?,
      remoteId: map['remoteId'] as String?,
      title: map['title'] as String? ?? '',
      details: map['details'] as String? ?? '',
      completed: (map['completed'] as int? ?? 0) == 1,
      synced: (map['synced'] as int? ?? 0) == 1,
      deleted: (map['deleted'] as int? ?? 0) == 1,
      updatedAt: DateTime.parse(
        map['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'remoteId': remoteId,
      'title': title,
      'details': details,
      'completed': completed ? 1 : 0,
      'synced': synced ? 1 : 0,
      'deleted': deleted ? 1 : 0,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: null, // Local DB id
      remoteId: doc.id,
      title: data['title'] as String? ?? '',
      details: data['details'] as String? ?? '',
      completed: data['completed'] as bool? ?? false,
      synced: true, // Since it's from Firestore
      deleted: data['deleted'] as bool? ?? false,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, Object?> toFirestoreMap() {
    return {
      'title': title,
      'details': details,
      'completed': completed,
      'deleted': deleted,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
