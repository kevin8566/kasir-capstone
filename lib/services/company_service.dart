class CompanyService {
  static final Map<String, dynamic> _mockProfile = {
    'name': 'KasirKu Demo',
    'tagline': 'Aplikasi Kasir Offline Mode',
    'logo_url': '',
    'address': 'Jl. Demo No. 123',
    'phone': '08123456789',
  };

  static Future<Map<String, dynamic>> getCompanyProfile() async {
    return _mockProfile;
  }

  static Future<void> updateCompanyProfile(Map<String, dynamic> data) async {
    _mockProfile.addAll(data);
  }

  static void clearCache() {}
}