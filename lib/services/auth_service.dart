class AuthService {
  static bool _isLoggedIn = false;
  static dynamic get currentUser => _isLoggedIn ? {'email': 'kasir@demo.com'} : null;
  static bool get isLoggedIn => _isLoggedIn;

  static Future<bool> login(String email, String password) async {
    // Mock login: always success for any password
    _isLoggedIn = true;
    return true;
  }

  static Future<void> logout() async {
    _isLoggedIn = false;
  }
}