/// Model class for the `owners` table.
class OwnerModel {
  final int? id;
  final String name;
  final String mobileNumber;
  final String pinHash; // SHA-256 hashed — never raw
  final String storeMode; // 'solo' | 'with_staff'
  final String createdAt;
  final String updatedAt;
  final String syncId; // UUID for Firebase sync

  const OwnerModel({
    this.id,
    required this.name,
    required this.mobileNumber,
    required this.pinHash,
    this.storeMode = 'solo',
    required this.createdAt,
    required this.updatedAt,
    required this.syncId,
  });

  factory OwnerModel.fromMap(Map<String, dynamic> map) => OwnerModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        mobileNumber: map['mobile_number'] as String,
        pinHash: map['pin_hash'] as String,
        storeMode: map['store_mode'] as String? ?? 'solo',
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String,
        syncId: map['sync_id'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'mobile_number': mobileNumber,
        'pin_hash': pinHash,
        'store_mode': storeMode,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'sync_id': syncId,
      };

  OwnerModel copyWith({
    int? id,
    String? name,
    String? mobileNumber,
    String? pinHash,
    String? storeMode,
    String? createdAt,
    String? updatedAt,
    String? syncId,
  }) =>
      OwnerModel(
        id: id ?? this.id,
        name: name ?? this.name,
        mobileNumber: mobileNumber ?? this.mobileNumber,
        pinHash: pinHash ?? this.pinHash,
        storeMode: storeMode ?? this.storeMode,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncId: syncId ?? this.syncId,
      );

  bool get isWithStaff => storeMode == 'with_staff';

  @override
  String toString() => 'OwnerModel(id: $id, name: $name)';
}
