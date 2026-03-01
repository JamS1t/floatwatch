import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/date_formatter.dart';
import '../data/models/markup_settings_model.dart';
import '../data/models/store_model.dart';
import '../data/repositories/interfaces/i_store_repository.dart';

/// StoreProvider manages the active store and its markup settings.
class StoreProvider extends ChangeNotifier {
  final IStoreRepository _storeRepo;

  StoreProvider({required IStoreRepository storeRepo}) : _storeRepo = storeRepo;

  // ── State ─────────────────────────────────────────────────────────────────
  StoreModel? _currentStore;
  List<StoreModel> _ownerStores = [];
  List<MarkupSettingsModel> _markupSettings = [];
  bool _isLoading = false;
  String? _error;

  StoreModel? get currentStore => _currentStore;
  List<StoreModel> get ownerStores => List.unmodifiable(_ownerStores);
  List<MarkupSettingsModel> get markupSettings =>
      List.unmodifiable(_markupSettings);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasStore => _currentStore != null;

  // ── Load ──────────────────────────────────────────────────────────────────

  /// Load the active store and its markup settings for the given owner.
  Future<void> loadStoreForOwner(int ownerId) async {
    _setLoading(true);
    try {
      _ownerStores = await _storeRepo.getStoresByOwner(ownerId);
      _currentStore = await _storeRepo.getActiveStoreForOwner(ownerId);
      if (_currentStore != null) {
        await _loadMarkupSettings();
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to load store.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadMarkupSettings() async {
    if (_currentStore?.id == null) return;
    _markupSettings = await _storeRepo.getMarkupSettings(_currentStore!.id!);
  }

  Future<void> refreshMarkupSettings() async {
    await _loadMarkupSettings();
    notifyListeners();
  }

  // ── Create ────────────────────────────────────────────────────────────────

  Future<bool> createStore({
    required int ownerId,
    required String storeName,
    String? location,
    String? gcashOutletNumber,
    String securityMode = 'simple',
  }) async {
    _setLoading(true);
    try {
      final now = DateFormatter.nowDb();
      final store = StoreModel(
        ownerId: ownerId,
        storeName: storeName,
        location: location,
        gcashOutletNumber: gcashOutletNumber,
        securityMode: securityMode,
        createdAt: now,
        updatedAt: now,
        syncId: const Uuid().v4(),
      );
      final id = await _storeRepo.createStore(store);
      _currentStore = store.copyWith(id: id);
      _ownerStores = [..._ownerStores, _currentStore!];
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create store.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Update ────────────────────────────────────────────────────────────────

  Future<bool> updateSecurityMode(String mode) async {
    if (_currentStore == null) return false;
    try {
      final updated = _currentStore!.copyWith(
        securityMode: mode,
        updatedAt: DateFormatter.nowDb(),
      );
      await _storeRepo.updateStore(updated);
      _currentStore = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update security mode.');
      return false;
    }
  }

  // ── Markup settings ───────────────────────────────────────────────────────

  Future<bool> saveMarkupSetting(MarkupSettingsModel setting) async {
    try {
      if (setting.id != null) {
        await _storeRepo.updateMarkupSetting(setting);
      } else {
        await _storeRepo.createMarkupSetting(setting);
      }
      await refreshMarkupSettings();
      return true;
    } catch (e) {
      _setError('Failed to save markup setting.');
      return false;
    }
  }

  MarkupSettingsModel? getMarkupForType(String transactionType) {
    try {
      return _markupSettings.firstWhere(
        (s) => s.transactionType == transactionType,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String msg) {
    _error = msg;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
