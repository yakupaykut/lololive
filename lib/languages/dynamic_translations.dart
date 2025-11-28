import 'package:get/get.dart';
import 'package:shortzz/common/manager/logger.dart';

class DynamicTranslations extends Translations {
  final Map<String, Map<String, String>> _keys = {};

  @override
  Map<String, Map<String, String>> get keys => _keys;

  void addTranslations(Map<String, Map<String, String>> map) {
    map.forEach((lang, translations) {
      if (_keys.containsKey(lang)) {
        _keys[lang]?.addAll(translations); // Update existing translations
        Loggers.info('Updated translations for language: $lang (${translations.length} keys added)');
      } else {
        _keys[lang] = translations; // Add new language
        Loggers.info('Added new language translations: $lang (${translations.length} keys)');
      }
    });
    
    // Log all available languages after update
    Loggers.info('Total languages loaded: ${_keys.keys.toList()}');
    _keys.forEach((lang, translations) {
      Loggers.info('Language $lang has ${translations.length} translations');
    });
  }
  
  bool hasLanguage(String langCode) {
    return _keys.containsKey(langCode) && (_keys[langCode]?.isNotEmpty ?? false);
  }
}
