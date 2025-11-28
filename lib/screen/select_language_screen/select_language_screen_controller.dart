import 'dart:io';
import 'dart:ui';

import 'package:get/get.dart';
import 'package:shortzz/common/controller/base_controller.dart';
import 'package:shortzz/common/manager/ads_manager.dart';
import 'package:shortzz/common/manager/logger.dart';
import 'package:shortzz/common/manager/session_manager.dart';
import 'package:shortzz/common/widget/eula_sheet.dart';
import 'package:shortzz/common/widget/restart_widget.dart';
import 'package:shortzz/languages/dynamic_translations.dart';
import 'package:shortzz/model/general/settings_model.dart';
import 'package:shortzz/screen/select_language_screen/select_language_screen.dart';

class SelectLanguageScreenController extends BaseController {
  Rx<Language?> selectedLanguage = Rx(null);
  RxList<Language> languages = <Language>[].obs;
  LanguageNavigationType languageNavigationType;

  Setting? get setting => SessionManager.instance.getSettings();
  SelectLanguageScreenController(this.languageNavigationType);

  @override
  void onInit() {
    super.onInit();
    initLanguage();
  }

  @override
  void onReady() {
    super.onReady();
    if (languageNavigationType == LanguageNavigationType.fromStart) {
      openEULASheet();
    }
    AdsManager.instance.requestConsentInfoUpdate();
  }

  Future<void> openEULASheet() async {
    if (Platform.isIOS) {
      bool shouldOpen = SessionManager.instance.shouldOpenEULASheet;

      await Future.delayed(const Duration(milliseconds: 250));
      Loggers.info('message  $shouldOpen');
      if (shouldOpen) {
        Get.bottomSheet(const EulaSheet(),
            isScrollControlled: true, enableDrag: false);
      }
    }
  }

  void initLanguage() {
    List<Language> items =
        SessionManager.instance.getSettings()?.languages ?? [];
    items.sort((a, b) => (a.title ?? '').compareTo(b.title ?? ''));
    for (Language element in items) {
      if (element.status == 1) {
        languages.add(element);
      }
    }
    String currentLang = SessionManager.instance.getLang();
    if (currentLang.isEmpty) {
      currentLang = SessionManager.instance.getFallbackLang();
    }
    try {
      selectedLanguage.value = languages.firstWhere((element) {
        return element.code == currentLang;
      });
    } catch (e) {
      // If current language not found, select first available language
      if (languages.isNotEmpty) {
        selectedLanguage.value = languages.first;
        SessionManager.instance.setLang(languages.first.code ?? 'tr');
      }
    }
  }

  void onLanguageChange(Language? value) {
    selectedLanguage.value = value;
    String langCode = value?.code ?? 'tr';
    
    // Check if translations are available for this language
    final translations = Get.find<DynamicTranslations>();
    bool hasTranslations = translations.hasLanguage(langCode);
    
    Loggers.info('Language changed to: $langCode, Has translations: $hasTranslations');
    
    // Log translation count for debugging
    if (hasTranslations) {
      int translationCount = translations.keys[langCode]?.length ?? 0;
      Loggers.info('Translation count for $langCode: $translationCount');
    }
    
    if (!hasTranslations) {
      Loggers.error('Translations not found for language: $langCode');
      showSnackBar('Translations not available for this language yet. Please wait...');
      return;
    }
    
    SessionManager.instance.setLang(langCode);
    
    // Update GetX locale immediately
    Get.updateLocale(Locale(langCode));
    
    Loggers.info('Locale updated, restarting app...');
    
    // Always restart app to ensure language changes are fully applied
    // This ensures MyApp rebuilds with the new locale
    Future.delayed(const Duration(milliseconds: 150), () {
      if (Get.context != null && Get.context!.mounted) {
        Loggers.info('Calling RestartWidget.restartApp()');
        RestartWidget.restartApp(Get.context!);
      } else {
        Loggers.error('Context is null or not mounted, cannot restart');
      }
    });
  }
}
