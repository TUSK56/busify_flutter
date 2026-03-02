import 'package:application/services/auth_service.dart';
import 'package:application/services/parent_service.dart';
import 'package:application/services/school_service.dart';
import 'package:application/services/supervisor_service.dart';
import 'package:application/services/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple service locator - call [init] from main() before runApp.
class ServiceLocator {
  static late TokenStorage tokenStorage;
  static late AuthService authService;
  static late SchoolService schoolService;
  static late ParentService parentService;
  static late SupervisorService supervisorService;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    tokenStorage = TokenStorage(prefs);
    authService = AuthService(tokenStorage);
    schoolService = SchoolService();
    parentService = ParentService(tokenStorage);
    supervisorService = SupervisorService(tokenStorage);
  }
}
