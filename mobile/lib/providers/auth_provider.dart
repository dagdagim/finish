import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  String get activeMode => _currentUser?.activeMode ?? 'customer';
  bool get isCustomerMode => activeMode == 'customer';
  bool get isTaskerMode => activeMode == 'tasker';

  Future<bool> login(String emailOrPhone, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _api.login(emailOrPhone, password);
    _isLoading = false;

    if (res['success'] == true) {
      _currentUser = res['user'];
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      _currentUser = null;
      _errorMessage = res['message'] ?? 'Login failed';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String password,
    String role = 'both',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _api.signup(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      email: email,
      password: password,
      role: role,
    );
    _isLoading = false;

    if (res['success'] == true) {
      _currentUser = res['user'];
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      _currentUser = null;
      _errorMessage = res['message'] ?? 'Signup failed';
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> sendGoogleOtp(String email, {String purpose = 'Google Sign-In / Register'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _api.sendGoogleOtp(email, purpose: purpose);
    _isLoading = false;
    if (res['success'] != true) {
      _errorMessage = res['message'] ?? 'Failed to send verification code';
    }
    notifyListeners();
    return res;
  }

  Future<Map<String, dynamic>> verifyGoogleOtp({
    required String email,
    required String otp,
    String? role,
    String? firstName,
    String? lastName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _api.verifyGoogleOtp(
      email: email,
      otp: otp,
      role: role,
      firstName: firstName,
      lastName: lastName,
    );
    _isLoading = false;

    if (res['success'] == true) {
      _currentUser = res['user'];
      _errorMessage = null;
      notifyListeners();
    } else {
      _errorMessage = res['message'] ?? 'OTP verification failed';
      notifyListeners();
    }
    return res;
  }

  Future<void> toggleMode() async {
    await switchMode();
  }

  Future<void> switchMode([String? targetMode]) async {
    if (_currentUser == null) return;
    final newMode = targetMode ?? (_currentUser!.activeMode == 'customer' ? 'tasker' : 'customer');
    _currentUser = _currentUser!.copyWith(activeMode: newMode);
    notifyListeners();
    await _api.switchMode(newMode);
  }

  void updateUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<bool> setDemoCustomer() async {
    return await login('sarah@finish.et', 'Finish2026!');
  }

  Future<bool> setDemoTasker() async {
    return await login('daniel@finish.et', 'Finish2026!');
  }

  Future<void> fetchMe() async {
    final user = await _api.getMe();
    if (user != null) {
      _currentUser = user;
      notifyListeners();
    }
  }

  void logout() {
    _currentUser = null;
    _errorMessage = null;
    _api.setToken('');
    notifyListeners();
  }
}
