import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/storage_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _client = ApiClient();
  final StorageService _storage = StorageService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _storage.getToken();
      if (token == null || token.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await _client.dio.get(ApiConstants.me);
      if (response.statusCode == 200 && response.data['success'] == true) {
        _currentUser = UserModel.fromJson(response.data['user']);
        await _storage.saveUserMeta(
          role: _currentUser!.role,
          shopName: _currentUser!.shopName,
          userName: _currentUser!.name,
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {
      await _storage.clearAuth();
    }

    _currentUser = null;
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> login(String mobile, String pin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _client.dio.post(
        ApiConstants.login,
        data: {'mobile': mobile.trim(), 'pin': pin.trim()},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final token = response.data['token'];
        _currentUser = UserModel.fromJson(response.data['user']);

        await _storage.saveToken(token);
        await _storage.saveUserMeta(
          role: _currentUser!.role,
          shopName: _currentUser!.shopName,
          userName: _currentUser!.name,
        );

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message'] ?? 'Login failed. Please check credentials.';
    } catch (_) {
      _errorMessage = 'Could not connect to server. Please try again.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String mobile,
    required String pin,
    required String name,
    required String shopName,
    String? role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _client.dio.post(
        ApiConstants.register,
        data: {
          'mobile': mobile.trim(),
          'pin': pin.trim(),
          'name': name.trim(),
          'shopName': shopName.trim(),
          ...?role == null ? null : {'role': role},
        },
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        final token = response.data['token'];
        _currentUser = UserModel.fromJson(response.data['user']);

        await _storage.saveToken(token);
        await _storage.saveUserMeta(
          role: _currentUser!.role,
          shopName: _currentUser!.shopName,
          userName: _currentUser!.name,
        );

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message'] ?? 'Registration failed.';
    } catch (_) {
      _errorMessage = 'Could not connect to server. Please try again.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _storage.clearAuth();
    _currentUser = null;
    notifyListeners();
  }
}
