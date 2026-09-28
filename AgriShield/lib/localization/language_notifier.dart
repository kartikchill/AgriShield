import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';
import '../services/api_service.dart';

class LanguageNotifier extends ChangeNotifier {
  static final LanguageNotifier instance = LanguageNotifier._internal();
  LanguageNotifier._internal();

  String _languageCode = ApiService.currentLanguageCode;
  String get languageCode => _languageCode;

  void setLanguage(String code) {
    if (_languageCode != code) {
      _languageCode = code;
      notifyListeners();
      
      ApiService.saveLanguage(code);

      // Enqueue sync for backend to update preferred locale
      DatabaseHelper.instance.enqueueSync(
        '/api/v1/users/locale',
        'PATCH',
        '{"locale": "$code"}',
      );
    }
  }
}
