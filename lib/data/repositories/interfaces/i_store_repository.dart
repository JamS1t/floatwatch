import '../../models/markup_settings_model.dart';
import '../../models/store_model.dart';

/// Repository interface for store and markup settings data.
// TODO: Add a FirebaseStoreRepository implementation for cloud sync.
abstract class IStoreRepository {
  Future<StoreModel?> getStore(int id);
  Future<List<StoreModel>> getStoresByOwner(int ownerId);
  Future<StoreModel?> getActiveStoreForOwner(int ownerId);
  Future<int> createStore(StoreModel store);
  Future<void> updateStore(StoreModel store);
  Future<void> deactivateStore(int id);

  // ── Markup Settings ───────────────────────────────────────────────────────
  Future<List<MarkupSettingsModel>> getMarkupSettings(int storeId);
  Future<MarkupSettingsModel?> getMarkupSettingForType(
    int storeId,
    String transactionType,
  );
  Future<int> createMarkupSetting(MarkupSettingsModel setting);
  Future<void> updateMarkupSetting(MarkupSettingsModel setting);
  Future<void> deleteMarkupSetting(int id);
}
