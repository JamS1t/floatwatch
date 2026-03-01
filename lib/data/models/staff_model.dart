/// Model class for the `staff` table.
class StaffModel {
  final int? id;
  final int ownerId;
  final int storeId;
  final String name;
  final String? mobileNumber;
  final String pinHash; // SHA-256 hashed — never raw
  final int isActive; // 1 = active, 0 = inactive
  final int isLocked; // 1 = locked after max failed attempts
  final int failedAttempts;
  final String? lastActive; // DB datetime string
  final String createdAt;
  final String updatedAt;
  final String syncId;

  const StaffModel({
    this.id,
    required this.ownerId,
    required this.storeId,
    required this.name,
    this.mobileNumber,
    required this.pinHash,
    this.isActive = 1,
    this.isLocked = 0,
    this.failedAttempts = 0,
    this.lastActive,
    required this.createdAt,
    required this.updatedAt,
    required this.syncId,
  });

  factory StaffModel.fromMap(Map<String, dynamic> map) => StaffModel(
        id: map['id'] as int?,
        ownerId: map['owner_id'] as int,
        storeId: map['store_id'] as int,
        name: map['name'] as String,
        mobileNumber: map['mobile_number'] as String?,
        pinHash: map['pin_hash'] as String,
        isActive: map['is_active'] as int? ?? 1,
        isLocked: map['is_locked'] as int? ?? 0,
        failedAttempts: map['failed_attempts'] as int? ?? 0,
        lastActive: map['last_active'] as String?,
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String,
        syncId: map['sync_id'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'owner_id': ownerId,
        'store_id': storeId,
        'name': name,
        'mobile_number': mobileNumber,
        'pin_hash': pinHash,
        'is_active': isActive,
        'is_locked': isLocked,
        'failed_attempts': failedAttempts,
        'last_active': lastActive,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'sync_id': syncId,
      };

  StaffModel copyWith({
    int? id,
    int? ownerId,
    int? storeId,
    String? name,
    String? mobileNumber,
    String? pinHash,
    int? isActive,
    int? isLocked,
    int? failedAttempts,
    String? lastActive,
    String? createdAt,
    String? updatedAt,
    String? syncId,
  }) =>
      StaffModel(
        id: id ?? this.id,
        ownerId: ownerId ?? this.ownerId,
        storeId: storeId ?? this.storeId,
        name: name ?? this.name,
        mobileNumber: mobileNumber ?? this.mobileNumber,
        pinHash: pinHash ?? this.pinHash,
        isActive: isActive ?? this.isActive,
        isLocked: isLocked ?? this.isLocked,
        failedAttempts: failedAttempts ?? this.failedAttempts,
        lastActive: lastActive ?? this.lastActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncId: syncId ?? this.syncId,
      );

  bool get active => isActive == 1;
  bool get locked => isLocked == 1;

  @override
  String toString() => 'StaffModel(id: $id, name: $name)';
}
