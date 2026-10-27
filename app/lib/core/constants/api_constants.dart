class ApiConstants {
  ApiConstants._();

  // Forwarded via ngrok tunnel to local backend server
  static const String baseUrl = 'https://thinness-embroider-gizzard.ngrok-free.dev/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';

  // Shop
  static const String shop = '/shop';

  // Products
  static const String products = '/products';
  static const String barcodeSearch = '/products/barcode';

  // Customers (Khata)
  static const String customers = '/customers';

  // Bills
  static const String bills = '/bills';

  // Reports
  static const String dashboard = '/reports/dashboard';
  static const String sales = '/reports/sales';
  static const String profit = '/reports/profit';
  static const String bestSellers = '/reports/best-sellers';

  // Admin
  static const String adminStats = '/admin/stats';
  static const String adminShops = '/admin/shops';
  static const String adminUsers = '/admin/users';
}

