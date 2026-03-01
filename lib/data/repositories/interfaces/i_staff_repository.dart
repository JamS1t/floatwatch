import '../../models/one_time_pin_model.dart';
import '../../models/staff_model.dart';

/// Repository interface for staff data.
// TODO: Add a FirebaseStaffRepository implementation for cloud sync.
abstract class IStaffRepository {
  Future<StaffModel?> getStaff(int id);
  Future<List<StaffModel>> getStaffByStore(int storeId);
  Future<List<StaffModel>> getActiveStaffByStore(int storeId);
  Future<int> createStaff(StaffModel staff);
  Future<void> updateStaff(StaffModel staff);
  Future<void> deactivateStaff(int id);
  Future<void> incrementFailedAttempts(int staffId);
  Future<void> resetFailedAttempts(int staffId);
  Future<void> lockStaff(int staffId);
  Future<void> unlockStaff(int staffId);
  Future<void> updateLastActive(int staffId, String timestamp);

  // ── One-time PINs ─────────────────────────────────────────────────────────
  Future<int> createOneTimePin(OneTimePinModel otp);
  Future<void> markOtpUsed(int otpId);
}
