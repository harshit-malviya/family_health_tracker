class SyncQueueItem {
  final int? id;
  final String entityType; // 'family_member', 'bp_reading', 'glucose_reading'
  final String entityId;
  final String action; // 'INSERT', 'UPDATE', 'DELETE'
  final String? payload; // JSON serialized string
  final String familyId;
  final DateTime createdAt;

  const SyncQueueItem({
    this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    this.payload,
    required this.familyId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'entityType': entityType,
      'entityId': entityId,
      'action': action,
      'payload': payload,
      'familyId': familyId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as int?,
      entityType: map['entityType'] as String,
      entityId: map['entityId'] as String,
      action: map['action'] as String,
      payload: map['payload'] as String?,
      familyId: map['familyId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

