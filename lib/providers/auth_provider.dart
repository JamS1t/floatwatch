import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/services/security_service.dart';
import '../core/utils/date_formatter.dart';
import '../data/models/owner_model.dart';
import '../data/models/staff_model.dart';
import '../data/repositories/interfaces/i_owner_repository.dart';
import '../data/repositories/interfaces/i_staff_repository.dart';

/// AuthProvider manages the authentication state for FloatWatch.
///
/// Flow:
///   Owner login  → [loginOwner]  → _currentOwner set, _currentStaff null
///   Staff login  → [loginStaff]  → _currentStaff set, _currentOwner null
///   Onboarding   → [createOwner] → creates owner record in DB
class AuthProvider extends ChangeNotifier {
  final IOwnerRepository _ownerRepo;
  final IStaffRepository _staffRepo;
  final SecurityService _security;

  AuthProvider({
    required IOwnerRepository ownerRepo,
    required IStaffRepository staffRepo,
    required SecurityService securityService,
  })  : _ownerRepo = ownerRepo,
        _staffRepo = staffRepo,
        _security = securityService;

  // ── State ─────────────────────────────────────────────────────────────────
  OwnerModel? _currentOwner;
  StaffModel? _currentStaff;
  bool _isLoading = false;
  String? _error;

  OwnerModel? get currentOwner => _currentOwner;
  StaffModel? get currentStaff => _currentStaff;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isOwnerLoggedIn => _currentOwner != null && _currentStaff == null;
  bool get isStaffLoggedIn => _currentStaff != null;
  bool get isLoggedIn => _currentOwner != null || _currentStaff != null;

  // ── Setup check ───────────────────────────────────────────────────────────

  /// Used by SplashScreen to decide whether to show onboarding or login.
  Future<bool> checkHasOwner() => _ownerRepo.hasOwner();

  // ── Owner login ───────────────────────────────────────────────────────────

  Future<List<OwnerModel>> getOwners() => _ownerRepo.getAllOwners();

  /// Verifies owner PIN and sets [_currentOwner] if correct.
  /// Returns true on success.
  Future<bool> loginOwner(int ownerId, String pin) async {
    _setLoading(true);
    _clearError();
    try {
      final owner = await _ownerRepo.getOwner(ownerId);
      if (owner == null) {
        _setError('Account not found.');
        return false;
      }
      if (!_security.verifyPin(pin, owner.pinHash)) {
        _setError('Incorrect PIN. Please try again.');
        return false;
      }
      _currentOwner = owner;
      _currentStaff = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Login failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Staff login ───────────────────────────────────────────────────────────

  Future<List<StaffModel>> getStaffForStore(int storeId) =>
      _staffRepo.getActiveStaffByStore(storeId);

  /// Verifies staff PIN. Increments failed attempts, locks after 3.
  /// Returns true on success.
  Future<bool> loginStaff(int staffId, String pin) async {
    _setLoading(true);
    _clearError();
    try {
      final staff = await _staffRepo.getStaff(staffId);
      if (staff == null) {
        _setError('Staff account not found.');
        return false;
      }
      if (staff.locked) {
        _setError('This account is locked. Contact the store owner.');
        return false;
      }
      if (!_security.verifyPin(pin, staff.pinHash)) {
        await _staffRepo.incrementFailedAttempts(staffId);
        final remaining = 3 - (staff.failedAttempts + 1);
        if (remaining <= 0) {
          _setError('Account locked after too many failed attempts.');
        } else {
          _setError('Incorrect PIN. $remaining attempt${remaining == 1 ? '' : 's'} left.');
        }
        return false;
      }
      // Success — reset failed attempts and update last active
      await _staffRepo.resetFailedAttempts(staffId);
      await _staffRepo.updateLastActive(staffId, DateFormatter.nowDb());
      _currentStaff = staff;
      _currentOwner = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Login failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Onboarding ────────────────────────────────────────────────────────────

  /// Creates a new owner account during onboarding.
  Future<bool> createOwner({
    required String name,
    required String mobileNumber,
    required String pin,
    required String storeMode,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final now = DateFormatter.nowDb();
      final owner = OwnerModel(
        name: name,
        mobileNumber: mobileNumber,
        pinHash: _security.hashPin(pin),
        storeMode: storeMode,
        createdAt: now,
        updatedAt: now,
        syncId: const Uuid().v4(),
      );
      final id = await _ownerRepo.createOwner(owner);
      _currentOwner = owner.copyWith(id: id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create account. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Change the current owner's PIN.
  Future<bool> changeOwnerPin({
    required String currentPin,
    required String newPin,
  }) async {
    if (_currentOwner == null) return false;
    _setLoading(true);
    _clearError();
    try {
      if (!_security.verifyPin(currentPin, _currentOwner!.pinHash)) {
        _setError('Current PIN is incorrect.');
        return false;
      }
      final updated = _currentOwner!.copyWith(
        pinHash: _security.hashPin(newPin),
        updatedAt: DateFormatter.nowDb(),
      );
      await _ownerRepo.updateOwner(updated);
      _currentOwner = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to change PIN. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  void logout() {
    _currentOwner = null;
    _currentStaff = null;
    _error = null;
    notifyListeners();
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

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
