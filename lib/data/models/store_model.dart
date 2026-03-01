/// Model class for the `stores` table.
class StoreModel {
  final int? id;
  final int ownerId;
  final String storeName;
  final String? location;
  final String? gcashOutletNumber;
  final String securityMode; // 'simple' | 'strict'
  final int isActive; // 1 = active, 0 = inactive
  final String createdAt;
  final String updatedAt;
  final String syncId;

  const StoreModel({
    this.id,
    required this.ownerId,
    required this.storeName,
    this.location,
    this.gcashOutletNumber,
    this.securityMode = 'simple',
    this.isActive = 1,
    required this.createdAt,
    required this.updatedAt,
    required this.syncId,
  });

  factory StoreModel.fromMap(Map<String, dynamic> map) => StoreModel(
        id: map['id'] as int?,
        ownerId: map['owner_id'] as int,
        storeName: map['store_name'] as String,
        location: map['location'] as String?,
        gcashOutletNumber: map['gcash_outlet_number'] as String?,
        securityMode: map['security_mode'] as String? ?? 'simple',
        isActive: map['is_active'] as int? ?? 1,
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String,
        syncId: map['sync_id'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'owner_id': ownerId,
        'store_name': storeName,
        'location': location,
        'gcash_outlet_number': gcashOutletNumber,
        'security_mode': securityMode,
        'is_active': isActive,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'sync_id': syncId,
      };

  StoreModel copyWith({
    int? id,
    int? ownerId,
    String? storeName,
    String? location,
    String? gcashOutletNumber,
    String? securityMode,
    int? isActive,
    String? createdAt,
    String? updatedAt,
    String? syncId,
  }) =>
      StoreModel(
        id: id ?? this.id,
        ownerId: ownerId ?? this.ownerId,
        storeName: storeName ?? this.storeName,
        location: location ?? this.location,
        gcashOutletNumber: gcashOutletNumber ?? this.gcashOutletNumber,
        securityMode: securityMode ?? this.securityMode,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncId: syncId ?? this.syncId,
      );

  bool get active => isActive == 1;
  bool get isStrict => securityMode == 'strict';

  @override
  String toString() => 'StoreModel(id: $id, storeName: $storeName)';
}
