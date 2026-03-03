import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/services/ocr_service.dart';
import 'core/services/receipt_storage_service.dart';
import 'core/services/security_service.dart';
import 'core/services/subscription_service.dart';
import 'data/database/database_helper.dart';
import 'data/repositories/interfaces/i_staff_repository.dart';
import 'data/repositories/local/local_daily_float_repository.dart';
import 'data/repositories/local/local_owner_repository.dart';
import 'data/repositories/local/local_report_repository.dart';
import 'data/repositories/local/local_staff_repository.dart';
import 'data/repositories/local/local_store_repository.dart';
import 'data/repositories/local/local_transaction_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/daily_float_provider.dart';
import 'providers/report_provider.dart';
import 'providers/store_provider.dart';
import 'providers/transaction_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Initialize Firebase when cloud sync is enabled:
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ── Initialize local database ────────────────────────────────────────────
  final dbHelper = DatabaseHelper.instance;
  await dbHelper.database; // Ensure all tables are created

  // ── Initialize services ──────────────────────────────────────────────────
  final securityService = SecurityService(dbHelper);
  final subscriptionService = SubscriptionService(dbHelper);

  // ── Initialize repositories ──────────────────────────────────────────────
  // TODO: Swap local repositories for Firebase repositories when cloud sync
  // is activated. Only these lines change — UI and ViewModels remain untouched.
  final ownerRepo = LocalOwnerRepository(dbHelper);
  final storeRepo = LocalStoreRepository(dbHelper);
  final staffRepo = LocalStaffRepository(dbHelper);
  final transactionRepo = LocalTransactionRepository(dbHelper);
  final dailyFloatRepo = LocalDailyFloatRepository(dbHelper);
  final reportRepo = LocalReportRepository(dbHelper);

  runApp(
    MultiProvider(
      providers: [
        // Singleton services (not ChangeNotifiers)
        Provider<SecurityService>.value(value: securityService),
        Provider<SubscriptionService>.value(value: subscriptionService),
        Provider<OcrService>(
          create: (_) => OcrService(),
          dispose: (_, s) => s.dispose(),
        ),
        Provider<ReceiptStorageService>.value(value: ReceiptStorageService()),
        // Repositories exposed for screens that need direct DB access
        Provider<IStaffRepository>.value(value: staffRepo),

        // State providers
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            ownerRepo: ownerRepo,
            staffRepo: staffRepo,
            securityService: securityService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => StoreProvider(storeRepo: storeRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => TransactionProvider(
            transactionRepo: transactionRepo,
            securityService: securityService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => DailyFloatProvider(dailyFloatRepo: dailyFloatRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => ReportProvider(reportRepo: reportRepo),
        ),
      ],
      child: const FloatWatchApp(),
    ),
  );
}
