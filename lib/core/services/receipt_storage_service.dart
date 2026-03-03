import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Copies receipt images from ImagePicker's temp directory to permanent
/// app storage so they survive across sessions.
class ReceiptStorageService {
  /// Copy [tempPath] to a permanent receipts directory.
  /// Uses [syncId] as the filename to match the transaction record.
  /// Returns the new permanent file path.
  Future<String> saveReceipt(String tempPath, String syncId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory('${appDir.path}/receipts');
    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }

    final ext = path.extension(tempPath);
    final destPath = '${receiptsDir.path}/$syncId$ext';
    await File(tempPath).copy(destPath);
    return destPath;
  }
}
