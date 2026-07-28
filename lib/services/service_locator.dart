import '../core/config/app_config.dart';
import 'auth/auth_service.dart';
import 'auth/mock_auth_service.dart';
import 'auth/firebase_auth_service.dart';
import 'database/database_service.dart';
import 'database/mock_database_service.dart';
import 'database/firestore_database_service.dart';

// ServiceLocator handles switching between mock data and real Firebase services.
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  late final AuthService authService;
  late final DatabaseService databaseService;

  void setup() {
    if (AppConfig.useMock) {
      authService = MockAuthService();
      databaseService = MockDatabaseService();
    } else {
      authService = FirebaseAuthService();
      databaseService = FirestoreDatabaseService();
    }
  }
}

final locator = ServiceLocator();
