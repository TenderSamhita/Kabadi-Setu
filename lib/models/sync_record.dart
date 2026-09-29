/// A queued offline operation waiting to be synced when connectivity returns.
///
/// NOTE: This is a local queue — the app has no server to sync with in the
/// hackathon prototype. This demonstrates the architecture and logs pending ops.
/// Sync against a real backend is listed on the Phase 2 roadmap (AGENTS.md).
class SyncRecord {
  final String syncId;
  /// 'lot' | 'priceRecord' | 'traceability'
  final String entityType;
  final String entityId;
  /// 'create' | 'update'
  final String operation;
  final DateTime createdAt;
  /// 'pending' | 'synced' | 'failed'
  String syncStatus;

  SyncRecord({
    required this.syncId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.createdAt,
    this.syncStatus = 'pending',
  });

  Map<String, dynamic> toJson() => {
        'syncId': syncId,
        'entityType': entityType,
        'entityId': entityId,
        'operation': operation,
        'createdAt': createdAt.toIso8601String(),
        'syncStatus': syncStatus,
      };

  factory SyncRecord.fromJson(Map<String, dynamic> json) => SyncRecord(
        syncId: json['syncId'] as String,
        entityType: json['entityType'] as String,
        entityId: json['entityId'] as String,
        operation: json['operation'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        syncStatus: (json['syncStatus'] as String?) ?? 'pending',
      );
}
