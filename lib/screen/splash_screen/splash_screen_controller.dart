import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:csv/csv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shortzz/common/controller/base_controller.dart';
import 'package:shortzz/common/extensions/string_extension.dart';
import 'package:shortzz/common/manager/logger.dart';
import 'package:shortzz/common/manager/session_manager.dart';
import 'package:shortzz/common/service/api/common_service.dart';
import 'package:shortzz/common/service/api/user_service.dart';
import 'package:shortzz/common/service/network_helper/network_helper.dart';
import 'package:shortzz/common/widget/no_internet_sheet.dart';
import 'package:shortzz/common/widget/restart_widget.dart';
import 'package:shortzz/languages/dynamic_translations.dart';
import 'package:shortzz/model/general/settings_model.dart';
import 'package:shortzz/screen/auth_screen/login_screen.dart';
import 'package:shortzz/screen/dashboard_screen/dashboard_screen.dart';
import 'package:shortzz/screen/on_boarding_screen/on_boarding_screen.dart';
import 'package:shortzz/screen/select_language_screen/select_language_screen.dart';
import 'package:shortzz/utilities/app_res.dart';

class SplashScreenController extends BaseController {
  late StreamSubscription _subscription;
  bool isOnline = true;

  @override
  void onReady() {
    super.onReady();

    Future.wait([fetchSettings()]);

    _subscription = NetworkHelper().onConnectionChange.listen((status) {
      isOnline = status;
      if (isOnline) {
        Get.back();
      } else {
        Get.to(() => const NoInternetSheet(), transition: Transition.downToUp);
      }
    });
  }

  @override
  void onClose() {
    super.onClose();
    _subscription.cancel();
  }

  Future<void> fetchSettings() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    bool showNavigate = await CommonService.instance.fetchGlobalSettings();
    if (showNavigate) {
      final translations = Get.find<DynamicTranslations>();
      var setting = SessionManager.instance.getSettings();
      var languages = setting?.languages ?? [];
      
      // Log settings information for debugging
      Loggers.info('=== Language Settings Debug ===');
      Loggers.info('Base URL: ${setting?.itemBaseUrl}');
      Loggers.info('Total languages: ${languages.length}');
      
      List<Language> downloadLanguages = languages.where((element) => element.status == 1).toList();
      
      // Log each language's CSV file URL
      for (var lang in downloadLanguages) {
        Loggers.info('Language: ${lang.code}, CSV File: ${lang.csvFile}');
      }
      
      if (downloadLanguages.isEmpty) {
        showSnackBar(AppRes.languageAdd, second: 5);
        return;
      }

      var downloadedFiles = await downloadAndParseLanguages(downloadLanguages);

      // Check if any languages were successfully downloaded
      if (downloadedFiles.isEmpty) {
        Loggers.error('No language files were successfully downloaded');
        showSnackBar('Failed to download language files. Please check your internet connection.', second: 5);
        // Continue anyway - app might have cached translations
      } else {
        translations.addTranslations(downloadedFiles);
        Loggers.info('Successfully loaded ${downloadedFiles.length} language files');
      }

      var defaultLang = languages.firstWhereOrNull((element) => element.isDefault == 1);

      if (defaultLang != null) {
        SessionManager.instance.setFallbackLang(defaultLang.code ?? 'en');
      }

      RestartWidget.restartApp(Get.context!);
      
      // Check if user is logged in
      bool loggedIn = SessionManager.instance.isLogin();
      
      if (loggedIn) {
        // Try to get user ID from stored user first
        int? userId = SessionManager.instance.getUserID();
        if (userId != null && userId > 0) {
          // Fetch user details from backend to validate session
          UserService.instance.fetchUserDetails(userId: userId).then((value) {
            if (value != null) {
              // Session is valid, update user data and go to dashboard
              SessionManager.instance.setUser(value);
              SessionManager.instance.setLogin(true);
              // Ensure language selection flag is set
              SessionManager.instance.setBool(SessionKeys.isLanguageScreenSelect, true);
              
              // Apply user's language preference only if no language is currently set
              String currentLang = SessionManager.instance.getLang();
              String fallbackLang = SessionManager.instance.getFallbackLang();
              
              // Only update language if current language is empty or is fallback language
              if ((currentLang.isEmpty || currentLang == fallbackLang) && 
                  value.appLanguage != null && value.appLanguage!.isNotEmpty) {
                SessionManager.instance.setLang(value.appLanguage!);
                // Update GetX locale immediately
                Get.updateLocale(Locale(value.appLanguage!));
              }
              
              Get.off(() => DashboardScreen(myUser: value));
            } else {
              // Session invalid, clear and go to login
              SessionManager.instance.clearSomeKey();
              SessionManager.instance.setLogin(false);
              _navigateToLoginOrLanguage();
            }
          }).catchError((error) {
            // On error, clear session and go to login
            SessionManager.instance.clearSomeKey();
            SessionManager.instance.setLogin(false);
            _navigateToLoginOrLanguage();
          });
        } else {
          // User ID not found, clear session and go to login
          SessionManager.instance.clearSomeKey();
          SessionManager.instance.setLogin(false);
          _navigateToLoginOrLanguage();
        }
      } else {
        // User not logged in, check for language/onboarding
        _navigateToLoginOrLanguage();
      }
    }
  }

  void _navigateToLoginOrLanguage() {
    bool isLanguageSelect = SessionManager.instance.getBool(SessionKeys.isLanguageScreenSelect);
    bool onBoardingShow = SessionManager.instance.getBool(SessionKeys.isOnBoardingScreenSelect);
    var setting = SessionManager.instance.getSettings();
    
    if (isLanguageSelect == false) {
      Get.off(() => const SelectLanguageScreen(languageNavigationType: LanguageNavigationType.fromStart));
    } else if (onBoardingShow == false && (setting?.onBoarding ?? []).isNotEmpty) {
      Get.off(() => const OnBoardingScreen());
      } else {
        Get.off(() => const LoginScreen());
      }
  }

  Future<Map<String, Map<String, String>>> downloadAndParseLanguages(List<Language> languages) async {
    const int maxConcurrentDownloads = 3; // Limit concurrent downloads
    final List<Future<void>> downloadTasks = [];
    final languageData = <String, Map<String, String>>{};

    for (var language in languages) {
      if (language.code != null && language.csvFile != null && language.csvFile!.isNotEmpty) {
        // Start the download
        downloadTasks.add(downloadAndProcessLanguage(language, languageData));
      }
    }

    // Process downloads in batches to limit concurrency
    for (int i = 0; i < downloadTasks.length; i += maxConcurrentDownloads) {
      final batch = downloadTasks.skip(i).take(maxConcurrentDownloads).toList();
      await Future.wait(batch);
    }

    return languageData;
  }

  Future<void> downloadAndProcessLanguage(Language language, Map<String, Map<String, String>> languageData) async {
    try {
      String? csvFileUrl = language.csvFile;
      if (csvFileUrl == null || csvFileUrl.isEmpty) {
        Loggers.error('CSV file URL is empty for language: ${language.code}');
        return;
      }

      // Check if base URL is available
      String? baseUrl = SessionManager.instance.getSettings()?.itemBaseUrl;
      if (baseUrl == null || baseUrl.isEmpty) {
        Loggers.error('Base URL is not available. Cannot download CSV for language: ${language.code}');
        return;
      }

      String fullUrl = baseUrl + csvFileUrl;
      Loggers.info('Downloading CSV from: $fullUrl for language: ${language.code}');

      final response = await http.get(Uri.parse(fullUrl)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Loggers.error('Timeout downloading CSV for language: ${language.code}');
          throw TimeoutException('Download timeout for ${language.code}');
        },
      );

      if (response.statusCode == 200) {
        final csvContent = utf8.decode(response.bodyBytes);
        
        // Validate CSV content is not empty
        if (csvContent.trim().isEmpty) {
          Loggers.error('CSV content is empty for language: ${language.code}');
          return;
        }

        // Parse the CSV into a map
        final parsedMap = _parseCsvToMap(csvContent);
        
        // Validate parsed map is not empty
        if (parsedMap.isEmpty) {
          Loggers.error('Parsed CSV map is empty for language: ${language.code}');
          return;
        }

        languageData[language.code!] = parsedMap;
        Loggers.info('Successfully downloaded and parsed: ${language.code} (${parsedMap.length} entries)');
      } else {
        Loggers.error('Failed to download ${language.code}: HTTP ${response.statusCode}');
      }
    } catch (e) {
      Loggers.error('Error downloading ${language.code}: $e');
    }
  }

  Map<String, String> _parseCsvToMap(String csvContent) {
    final rows = const CsvToListConverter().convert(csvContent);
    final map = <String, String>{};

    for (var row in rows) {
      if (row.length >= 2) {
        map[row[0].toString()] = row[1].toString();
      }
    }
    return map;
  }
}
