import '../../models/owner_model.dart';

/// Repository interface for owner data.
///
/// All database operations on the `owners` table must go through this
/// interface. The local SQLite implementation lives in LocalOwnerRepository.
/// TODO: Add a FirebaseOwnerRepository that implements this interface when
/// cloud sync is activated — no other code needs to change.
abstract class IOwnerRepository {
  Future<OwnerModel?> getOwner(int id);
  Future<OwnerModel?> getOwnerByMobileNumber(String mobileNumber);
  Future<List<OwnerModel>> getAllOwners();
  Future<int> createOwner(OwnerModel owner);
  Future<void> updateOwner(OwnerModel owner);
  Future<void> deleteOwner(int id);

  /// Returns true if at least one owner exists (used by splash screen).
  Future<bool> hasOwner();
}
