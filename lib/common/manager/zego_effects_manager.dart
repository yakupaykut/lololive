import 'package:zego_effects_plugin/zego_effects_plugin.dart';
import 'package:zego_effects_plugin/zego_effects_defines.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:shortzz/common/manager/logger.dart';
import 'package:shortzz/common/manager/session_manager.dart';
import 'package:shortzz/model/general/settings_model.dart';

class ZegoEffectsManager {
  static final ZegoEffectsManager _instance = ZegoEffectsManager._internal();
  factory ZegoEffectsManager() => _instance;
  ZegoEffectsManager._internal();

  bool _isInitialized = false;
  bool _isImageProcessingEnabled = false;
  String? _currentFilter;

  Setting? get _setting => SessionManager.instance.getSettings();

  /// Zego AI Effects'i initialize et
  Future<bool> initialize() async {
    if (_isInitialized) {
      Loggers.info('ZegoEffects already initialized');
      return true;
    }

    try {
      // AppID ve AppSign'ı settings'den al
      String? appIDStr = _setting?.zegoAppId;
      String? appSign = _setting?.zegoAppSign;

      if (appIDStr == null || appIDStr.isEmpty || 
          appSign == null || appSign.isEmpty) {
        Loggers.error('Zego AppID or AppSign not configured');
        return false;
      }

      int appID = int.tryParse(appIDStr) ?? 0;
      if (appID == 0) {
        Loggers.error('Invalid Zego AppID: $appIDStr');
        return false;
      }

      // 1. Resources'ları yükle (MUTLAKA ÖNCE!)
      Loggers.info('Loading Zego Effects resources...');
      await ZegoEffectsPlugin.instance.setResources();
      Loggers.info('Zego Effects resources loaded');

      // 2. SDK'yı başlat
      Loggers.info('Creating Zego Effects SDK with AppID: $appID');
      try {
        await ZegoEffectsPlugin.instance.create(appID, appSign);
        Loggers.info('Zego Effects SDK created');
      } catch (licenseError) {
        // Lisans hatası olsa bile devam et (test amaçlı)
        if (licenseError.toString().contains('5100006') || 
            licenseError.toString().contains('License') ||
            licenseError.toString().contains('鉴权失败')) {
          Loggers.warning('⚠️ Zego Effects license error detected (5100006)');
          Loggers.warning('⚠️ Continuing anyway - effects may not work properly');
          Loggers.warning('⚠️ Please contact Zego support to enable Effects SDK');
          // Yine de devam et, belki beauty efektleri çalışır
        } else {
          rethrow; // Başka bir hata ise fırlat
        }
      }

      // 3. Zego Express Engine ile entegre et
      await _enableCustomVideoProcessing();

      _isInitialized = true;
      Loggers.success('ZegoEffects initialized successfully');
      return true;
    } catch (e, stackTrace) {
      Loggers.error('Failed to initialize ZegoEffects: $e\n$stackTrace');
      
      // Lisans hatası kontrolü
      if (e.toString().contains('5100006') || 
          e.toString().contains('License') ||
          e.toString().contains('license')) {
        Loggers.error('⚠️ ZEGO EFFECTS LICENSE ERROR: Zego Effects SDK için lisans doğrulaması başarısız!');
        Loggers.error('⚠️ Zego Dashboard\'dan Effects SDK yetkisini açmanız gerekebilir.');
      }
      
      return false;
    }
  }

  /// Custom video processing'i etkinleştir
  Future<void> _enableCustomVideoProcessing() async {
    try {
      // Zego Express Engine'de custom video processing'i aç
      ZegoCustomVideoProcessConfig config = ZegoCustomVideoProcessConfig(
        ZegoVideoBufferType.GLTexture2D, // Texture mode (daha hızlı)
      );
      await ZegoExpressEngine.instance.enableCustomVideoProcessing(true, config);

      // ZegoEffects image processing'i etkinleştir
      await ZegoEffectsPlugin.instance.enableImageProcessing(true);
      _isImageProcessingEnabled = true;

      Loggers.success('Custom video processing enabled');
    } catch (e, stackTrace) {
      Loggers.error('Failed to enable custom video processing: $e\n$stackTrace');
      throw e;
    }
  }

  /// Filtre uygula
  Future<bool> applyFilter(String filterName) async {
    if (!_isInitialized) {
      Loggers.error('ZegoEffects not initialized');
      return false;
    }

    // Image processing açık değilse aç
    if (!_isImageProcessingEnabled) {
      Loggers.warning('Image processing is disabled, enabling it...');
      await toggleImageProcessing(true);
    }

    try {
      Loggers.info('Applying filter: $filterName');
      await ZegoEffectsPlugin.instance.setFilter(filterName);
      _currentFilter = filterName;
      Loggers.success('Filter applied successfully: $filterName');
      return true;
    } catch (e, stackTrace) {
      Loggers.error('Failed to apply filter: $e');
      Loggers.error('Stack trace: $stackTrace');
      
      // Lisans hatası kontrolü
      if (e.toString().contains('5100006') || 
          e.toString().contains('License')) {
        Loggers.error('⚠️ LICENSE ERROR: Efektler lisans hatası nedeniyle uygulanamıyor!');
      }
      
      return false;
    }
  }

  /// Filtre intensity ayarla
  Future<void> setFilterIntensity(int intensity) async {
    if (!_isInitialized || _currentFilter == null) return;

    try {
      ZegoEffectsFilterParam param = ZegoEffectsFilterParam();
      param.intensity = intensity.clamp(0, 100);
      await ZegoEffectsPlugin.instance.setFilterParam(param);
      Loggers.info('Filter intensity set to: $intensity');
    } catch (e) {
      Loggers.error('Failed to set filter intensity: $e');
    }
  }

  /// Filtreyi kaldır
  Future<void> removeFilter() async {
    if (!_isInitialized) return;

    try {
      await ZegoEffectsPlugin.instance.setFilter('');
      _currentFilter = null;
      Loggers.info('Filter removed');
    } catch (e) {
      Loggers.error('Failed to remove filter: $e');
    }
  }

  /// Beauty settings uygula
  /// Beauty için ayrı metodlar kullanılıyor: setWhitenParam, setSmoothParam, setSharpenParam, setRosyParam
  Future<void> setBeautySettings({
    double? smoothness,      // 0-100 -> smoothIntensity
    double? skinTone,        // 0-100 -> rosyIntensity (gül renk)
    double? sharpness,       // 0-100 -> sharpenIntensity
    double? whiteness,       // 0-100 -> whitenIntensity
  }) async {
    if (!_isInitialized) {
      Loggers.error('ZegoEffects not initialized, cannot apply beauty settings');
      return;
    }

    // Image processing açık değilse aç
    if (!_isImageProcessingEnabled) {
      Loggers.warning('Image processing is disabled, enabling it...');
      await toggleImageProcessing(true);
    }

    try {
      // Whiten (beyazlatma)
      if (whiteness != null) {
        ZegoEffectsWhitenParam whitenParam = ZegoEffectsWhitenParam();
        whitenParam.intensity = whiteness.clamp(0, 100).toInt();
        await ZegoEffectsPlugin.instance.setWhitenParam(whitenParam);
      }

      // Smooth (pürüzsüzleştirme)
      if (smoothness != null) {
        ZegoEffectsSmoothParam smoothParam = ZegoEffectsSmoothParam();
        smoothParam.intensity = smoothness.clamp(0, 100).toInt();
        await ZegoEffectsPlugin.instance.setSmoothParam(smoothParam);
      }

      // Sharpen (keskinleştirme)
      if (sharpness != null) {
        ZegoEffectsSharpenParam sharpenParam = ZegoEffectsSharpenParam();
        sharpenParam.intensity = sharpness.clamp(0, 100).toInt();
        await ZegoEffectsPlugin.instance.setSharpenParam(sharpenParam);
      }

      // Rosy (gül rengi)
      if (skinTone != null) {
        ZegoEffectsRosyParam rosyParam = ZegoEffectsRosyParam();
        rosyParam.intensity = skinTone.clamp(0, 100).toInt();
        await ZegoEffectsPlugin.instance.setRosyParam(rosyParam);
      }

      Loggers.info('Beauty settings updated');
    } catch (e) {
      Loggers.error('Failed to set beauty settings: $e');
    }
  }

  /// Image processing'i aç/kapat
  Future<void> toggleImageProcessing(bool enable) async {
    if (!_isInitialized) return;

    try {
      await ZegoEffectsPlugin.instance.enableImageProcessing(enable);
      _isImageProcessingEnabled = enable;
      Loggers.info('Image processing ${enable ? "enabled" : "disabled"}');
    } catch (e) {
      Loggers.error('Failed to toggle image processing: $e');
    }
  }

  /// Cleanup
  Future<void> dispose() async {
    try {
      await ZegoEffectsPlugin.instance.enableImageProcessing(false);
      // enableCustomVideoProcessing requires config parameter
      ZegoCustomVideoProcessConfig config = ZegoCustomVideoProcessConfig(
        ZegoVideoBufferType.GLTexture2D,
      );
      await ZegoExpressEngine.instance.enableCustomVideoProcessing(false, config);
    } catch (e) {
      Loggers.error('Error disposing ZegoEffects: $e');
    }

    _isInitialized = false;
    _isImageProcessingEnabled = false;
    _currentFilter = null;
    Loggers.info('ZegoEffects disposed');
  }

  /// Face Lifting (Yüz Germe)
  Future<void> setFaceLifting({required int intensity, required bool enable}) async {
    if (!_isInitialized) {
      Loggers.error('ZegoEffects not initialized, cannot apply face lifting');
      return;
    }

    if (!_isImageProcessingEnabled) {
      await toggleImageProcessing(true);
    }

    try {
      await ZegoEffectsPlugin.instance.enableFaceLifting(enable);
      if (enable) {
        ZegoEffectsFaceLiftingParam param = ZegoEffectsFaceLiftingParam();
        param.intensity = intensity.clamp(0, 100);
        await ZegoEffectsPlugin.instance.setFaceLiftingParam(param);
      }
    } catch (e) {
      Loggers.error('Failed to set face lifting: $e');
    }
  }

  /// Big Eyes (Büyük Gözler)
  Future<void> setBigEyes(int intensity) async {
    if (!_isInitialized) {
      Loggers.error('ZegoEffects not initialized, cannot apply big eyes');
      return;
    }

    if (!_isImageProcessingEnabled) {
      await toggleImageProcessing(true);
    }

    try {
      ZegoEffectsBigEyesParam param = ZegoEffectsBigEyesParam();
      param.intensity = intensity.clamp(0, 100);
      await ZegoEffectsPlugin.instance.setBigEyesParam(param);
    } catch (e) {
      Loggers.error('Failed to set big eyes: $e');
    }
  }

  /// Wrinkles Removing (Kırışıklık Giderme)
  Future<void> setWrinklesRemoving(int intensity) async {
    if (!_isInitialized) {
      Loggers.error('ZegoEffects not initialized, cannot apply wrinkles removing');
      return;
    }

    if (!_isImageProcessingEnabled) {
      await toggleImageProcessing(true);
    }

    try {
      ZegoEffectsWrinklesRemovingParam param = ZegoEffectsWrinklesRemovingParam();
      param.intensity = intensity.clamp(0, 100);
      await ZegoEffectsPlugin.instance.setWrinklesRemovingParam(param);
    } catch (e) {
      Loggers.error('Failed to set wrinkles removing: $e');
    }
  }

  /// Dark Circles Removing (Göz Altı Morluğu Giderme)
  Future<void> setDarkCirclesRemoving(int intensity) async {
    if (!_isInitialized) {
      Loggers.error('ZegoEffects not initialized, cannot apply dark circles removing');
      return;
    }

    if (!_isImageProcessingEnabled) {
      await toggleImageProcessing(true);
    }

    try {
      ZegoEffectsDarkCirclesRemovingParam param = ZegoEffectsDarkCirclesRemovingParam();
      param.intensity = intensity.clamp(0, 100);
      await ZegoEffectsPlugin.instance.setDarkCirclesRemovingParam(param);
    } catch (e) {
      Loggers.error('Failed to set dark circles removing: $e');
    }
  }

  /// Pendant (Aksesuar) uygula - Şapka, maske vb. 3D objeler
  Future<bool> applyPendant(String pendantName) async {
    if (!_isInitialized) {
      Loggers.error('ZegoEffects not initialized');
      return false;
    }

    if (!_isImageProcessingEnabled) {
      await toggleImageProcessing(true);
    }

    try {
      if (pendantName.isEmpty) {
        // Pendant'ı kaldır
        await ZegoEffectsPlugin.instance.setPendant('');
      } else {
        await ZegoEffectsPlugin.instance.setPendant(pendantName);
      }
      Loggers.success('Pendant applied: $pendantName');
      return true;
    } catch (e) {
      Loggers.error('Failed to apply pendant: $e');
      return false;
    }
  }

  /// Pendant dosya yolu ile uygula
  Future<bool> applyPendantPath(String path) async {
    if (!_isInitialized) {
      Loggers.error('ZegoEffects not initialized');
      return false;
    }

    if (!_isImageProcessingEnabled) {
      await toggleImageProcessing(true);
    }

    try {
      await ZegoEffectsPlugin.instance.setPendantPath(path);
      Loggers.success('Pendant applied from path: $path');
      return true;
    } catch (e) {
      Loggers.error('Failed to apply pendant path: $e');
      return false;
    }
  }

  /// Makeup (Makyaj) uygula - Otomatik makyaj paketleri
  Future<bool> applyMakeup(String makeupName) async {
    if (!_isInitialized) {
      Loggers.error('ZegoEffects not initialized');
      return false;
    }

    if (!_isImageProcessingEnabled) {
      await toggleImageProcessing(true);
    }

    try {
      if (makeupName.isEmpty) {
        await ZegoEffectsPlugin.instance.setMakeup('');
      } else {
        await ZegoEffectsPlugin.instance.setMakeup(makeupName);
      }
      Loggers.success('Makeup applied: $makeupName');
      return true;
    } catch (e) {
      Loggers.error('Failed to apply makeup: $e');
      return false;
    }
  }

  /// Eyeliner (Göz Kalemi) uygula
  Future<bool> applyEyeliner(String eyelinerName, {int? intensity}) async {
    if (!_isInitialized) {
      Loggers.error('ZegoEffects not initialized');
      return false;
    }

    if (!_isImageProcessingEnabled) {
      await toggleImageProcessing(true);
    }

    try {
      if (eyelinerName.isEmpty) {
        await ZegoEffectsPlugin.instance.setEyeliner('');
      } else {
        await ZegoEffectsPlugin.instance.setEyeliner(eyelinerName);
        if (intensity != null && intensity > 0) {
          ZegoEffectsEyelinerParam param = ZegoEffectsEyelinerParam();
          param.intensity = intensity.clamp(0, 100);
          await ZegoEffectsPlugin.instance.setEyelinerParam(param);
        }
      }
      Loggers.success('Eyeliner applied: $eyelinerName');
      return true;
    } catch (e) {
      Loggers.error('Failed to apply eyeliner: $e');
      return false;
    }
  }

  /// Eyeshadow (Göz Farı) uygula
  Future<bool> applyEyeshadow(String eyeshadowName, {int? intensity}) async {
    if (!_isInitialized) {
      Loggers.error('ZegoEffects not initialized');
      return false;
    }

    if (!_isImageProcessingEnabled) {
      await toggleImageProcessing(true);
    }

    try {
      if (eyeshadowName.isEmpty) {
        await ZegoEffectsPlugin.instance.setEyeshadow('');
      } else {
        await ZegoEffectsPlugin.instance.setEyeshadow(eyeshadowName);
        if (intensity != null && intensity > 0) {
          ZegoEffectsEyeshadowParam param = ZegoEffectsEyeshadowParam();
          param.intensity = intensity.clamp(0, 100);
          await ZegoEffectsPlugin.instance.setEyeshadowParam(param);
        }
      }
      Loggers.success('Eyeshadow applied: $eyeshadowName');
      return true;
    } catch (e) {
      Loggers.error('Failed to apply eyeshadow: $e');
      return false;
    }
  }

  bool get isInitialized => _isInitialized;
  bool get isImageProcessingEnabled => _isImageProcessingEnabled;
  String? get currentFilter => _currentFilter;
}

