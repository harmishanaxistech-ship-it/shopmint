import 'package:flutter/material.dart';
import '../storage/storage_service.dart';
import 'app_strings.dart';

class LocaleProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();

  String _currentLanguage = 'en'; // Default to English
  late AppStrings _strings;

  LocaleProvider() {
    _strings = AppStrings(_currentLanguage);
    _loadSavedLanguage();
  }

  String get currentLanguage => _currentLanguage;
  AppStrings get strings => _strings;

  String t(String key) => _strings.get(key);

  Future<void> _loadSavedLanguage() async {
    final saved = await _storage.getLanguage();
    if (saved != _currentLanguage) {
      _currentLanguage = saved;
      _strings = AppStrings(_currentLanguage);
      notifyListeners();
    }
  }

  Future<void> setLocale(String languageCode) async {
    if (languageCode == 'en' || languageCode == 'gu' || languageCode == 'hi') {
      _currentLanguage = languageCode;
      _strings = AppStrings(languageCode);
      await _storage.saveLanguage(languageCode);
      notifyListeners();
    }
  }

  String getLanguageName(String code) {
    switch (code) {
      case 'gu':
        return 'ગુજરાતી (Gujarati)';
      case 'hi':
        return 'हिन्दी (Hindi)';
      case 'en':
      default:
        return 'English';
    }
  }
}

