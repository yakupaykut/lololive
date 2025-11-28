import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:shortzz/common/widget/bottom_sheet_top_view.dart';
import 'package:shortzz/common/extensions/string_extension.dart';
import 'package:shortzz/languages/languages_keys.dart';
import 'package:shortzz/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:shortzz/utilities/text_style_custom.dart';
import 'package:shortzz/utilities/theme_res.dart';
import 'package:shortzz/utilities/color_res.dart';
import 'package:shortzz/utilities/asset_res.dart';

// Zego Effects Filter Model
class ZegoEffectFilter {
  final String id;
  final String name;
  final String filterName;
  final String thumbnailUrl;
  final String category;

  ZegoEffectFilter({
    required this.id,
    required this.name,
    required this.filterName,
    required this.thumbnailUrl,
    required this.category,
  });
}

// Pendant Model (Aksesuarlar - Şapka, maske vb.)
class PendantEffect {
  final String id;
  final String name;
  final String pendantName;
  final IconData icon;

  PendantEffect({
    required this.id,
    required this.name,
    required this.pendantName,
    required this.icon,
  });
}

// Makeup Model (Makyaj paketleri)
class MakeupEffect {
  final String id;
  final String name;
  final String makeupName;
  final IconData icon;

  MakeupEffect({
    required this.id,
    required this.name,
    required this.makeupName,
    required this.icon,
  });
}

enum EffectsTab { filters, beauty, masks, pendants, makeup }

class EffectsSheet extends StatefulWidget {
  const EffectsSheet({super.key});

  @override
  State<EffectsSheet> createState() => _EffectsSheetState();
}

class _EffectsSheetState extends State<EffectsSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  EffectsTab _currentTab = EffectsTab.filters;

  // Beauty settings state
  double _whiteness = 50.0;
  double _smoothness = 50.0;
  double _sharpness = 50.0;
  double _rosy = 50.0;

  // Mask settings state
  bool _faceLiftingEnabled = false;
  double _faceLifting = 50.0;
  double _bigEyes = 50.0;
  double _wrinklesRemoving = 50.0;
  double _darkCirclesRemoving = 50.0;

  // Selected effects
  String? _selectedPendant;
  String? _selectedMakeup;

  // Built-in Zego Effects filters
  final List<ZegoEffectFilter> _allFilters = [
    ZegoEffectFilter(
      id: 'none',
      name: 'Orijinal',
      filterName: '',
      thumbnailUrl: 'assets/images/ic_no_filter.png',
      category: 'popular',
    ),
    ZegoEffectFilter(
      id: 'natural',
      name: 'Doğal',
      filterName: 'Natural',
      thumbnailUrl: 'assets/images/ic_no_filter.png',
      category: 'popular',
    ),
    ZegoEffectFilter(
      id: 'warm',
      name: 'Sıcak',
      filterName: 'Warm',
      thumbnailUrl: 'assets/images/ic_no_filter.png',
      category: 'popular',
    ),
    ZegoEffectFilter(
      id: 'cool',
      name: 'Soğuk',
      filterName: 'Cool',
      thumbnailUrl: 'assets/images/ic_no_filter.png',
      category: 'popular',
    ),
    ZegoEffectFilter(
      id: 'vintage',
      name: 'Vintage',
      filterName: 'Vintage',
      thumbnailUrl: 'assets/images/ic_no_filter.png',
      category: 'artistic',
    ),
    ZegoEffectFilter(
      id: 'bright',
      name: 'Parlak',
      filterName: 'Bright',
      thumbnailUrl: 'assets/images/ic_no_filter.png',
      category: 'artistic',
    ),
    ZegoEffectFilter(
      id: 'night',
      name: 'Gece',
      filterName: 'Night',
      thumbnailUrl: 'assets/images/ic_no_filter.png',
      category: 'artistic',
    ),
  ];

  // Pendant effects (Aksesuarlar - Şapka, maske vb.)
  final List<PendantEffect> _pendants = [
    PendantEffect(
      id: 'none',
      name: 'Yok',
      pendantName: '',
      icon: Icons.clear,
    ),
    PendantEffect(
      id: 'hat1',
      name: 'Şapka 1',
      pendantName: 'Hat1', // Zego pendant name
      icon: Icons.checkroom,
    ),
    PendantEffect(
      id: 'hat2',
      name: 'Şapka 2',
      pendantName: 'Hat2',
      icon: Icons.checkroom_outlined,
    ),
    PendantEffect(
      id: 'mask1',
      name: 'Maske 1',
      pendantName: 'Mask1',
      icon: Icons.masks,
    ),
    PendantEffect(
      id: 'glasses1',
      name: 'Gözlük 1',
      pendantName: 'Glasses1',
      icon: Icons.face_retouching_natural,
    ),
    PendantEffect(
      id: 'glasses2',
      name: 'Gözlük 2',
      pendantName: 'Glasses2',
      icon: Icons.visibility,
    ),
  ];

  // Makeup effects (Makyaj paketleri)
  final List<MakeupEffect> _makeups = [
    MakeupEffect(
      id: 'none',
      name: 'Yok',
      makeupName: '',
      icon: Icons.clear,
    ),
    MakeupEffect(
      id: 'natural_makeup',
      name: 'Doğal Makyaj',
      makeupName: 'Natural',
      icon: Icons.face,
    ),
    MakeupEffect(
      id: 'party_makeup',
      name: 'Parti Makyajı',
      makeupName: 'Party',
      icon: Icons.celebration,
    ),
    MakeupEffect(
      id: 'elegant_makeup',
      name: 'Şık Makyaj',
      makeupName: 'Elegant',
      icon: Icons.star,
    ),
    MakeupEffect(
      id: 'cute_makeup',
      name: 'Sevimli Makyaj',
      makeupName: 'Cute',
      icon: Icons.favorite,
    ),
    MakeupEffect(
      id: 'dramatic_makeup',
      name: 'Dramatik Makyaj',
      makeupName: 'Dramatic',
      icon: Icons.theater_comedy,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTab = EffectsTab.values[_tabController.index];
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LivestreamScreenController>();

    return Container(
      height: Get.height * 0.75,
      margin: EdgeInsets.only(top: AppBar().preferredSize.height * 2),
      decoration: ShapeDecoration(
        color: whitePure(context),
        shape: const SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius.vertical(
            top: SmoothRadius(cornerRadius: 30, cornerSmoothing: 1),
          ),
        ),
      ),
      child: Column(
        children: [
          BottomSheetTopView(
            title: 'Efektler',
            sideBtnVisibility: false,
          ),
          
          // Effects Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Efektleri Aç',
                  style: TextStyleCustom.unboundedMedium500(
                    color: blackPure(context),
                    fontSize: 16,
                  ),
                ),
                Obx(() => Switch(
                  value: controller.isEffectsEnabled.value,
                  onChanged: (value) => controller.toggleEffects(value),
                  activeColor: ColorRes.blueFollow,
                )),
              ],
            ),
          ),

          // Category Tabs
          Container(
            height: 50,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: ColorRes.blueFollow,
              unselectedLabelColor: textLightGrey(context),
              indicatorColor: ColorRes.blueFollow,
              indicatorWeight: 2,
              labelStyle: TextStyleCustom.unboundedMedium500(fontSize: 13),
              unselectedLabelStyle: TextStyleCustom.unboundedRegular400(fontSize: 13),
              tabs: const [
                Tab(text: 'Filtreler'),
                Tab(text: 'Güzellik'),
                Tab(text: 'Maskeler'),
                Tab(text: 'Aksesuarlar'),
                Tab(text: 'Makyaj'),
              ],
            ),
          ),

          // Content based on selected tab
          Expanded(
            child: Obx(() {
              if (!controller.isEffectsEnabled.value) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.filter_alt_off,
                        size: 64,
                        color: textLightGrey(context),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Efektleri açmak için yukarıdaki anahtarı kullanın',
                        style: TextStyleCustom.unboundedRegular400(
                          color: textLightGrey(context),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildFiltersTab(context, controller),
                  _buildBeautyTab(context, controller),
                  _buildMasksTab(context, controller),
                  _buildPendantsTab(context, controller),
                  _buildMakeupTab(context, controller),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersTab(BuildContext context, LivestreamScreenController controller) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _allFilters.length,
      itemBuilder: (context, index) {
        final filter = _allFilters[index];
        final isSelected = controller.selectedFilterName.value == filter.filterName;

        return GestureDetector(
          onTap: () {
            if (filter.filterName.isEmpty) {
              controller.removeFilter();
            } else {
              controller.applyFilter(filter.filterName);
            }
            Get.back();
          },
          child: Container(
            decoration: BoxDecoration(
              color: bgLightGrey(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? ColorRes.blueFollow
                    : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: whitePure(context),
                    border: Border.all(
                      color: isSelected
                          ? ColorRes.blueFollow
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: filter.id == 'none'
                        ? Image.asset(
                            AssetRes.icNoFilter,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: ColorRes.blueFollow.withOpacity(0.1),
                            child: Icon(
                              _getFilterIcon(filter.filterName),
                              color: isSelected
                                  ? ColorRes.blueFollow
                                  : textLightGrey(context),
                              size: 32,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    filter.name,
                    style: TextStyleCustom.unboundedMedium500(
                      color: isSelected
                          ? ColorRes.blueFollow
                          : blackPure(context),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBeautyTab(BuildContext context, LivestreamScreenController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBeautySlider(
            context,
            'Beyazlatma',
            Icons.wb_sunny,
            _whiteness,
            (value) {
              setState(() => _whiteness = value);
              controller.applyBeautySettings(
                whiteness: value,
                smoothness: _smoothness,
                sharpness: _sharpness,
                rosy: _rosy,
              );
            },
          ),
          const SizedBox(height: 24),
          _buildBeautySlider(
            context,
            'Pürüzsüzleştirme',
            Icons.auto_awesome,
            _smoothness,
            (value) {
              setState(() => _smoothness = value);
              controller.applyBeautySettings(
                whiteness: _whiteness,
                smoothness: value,
                sharpness: _sharpness,
                rosy: _rosy,
              );
            },
          ),
          const SizedBox(height: 24),
          _buildBeautySlider(
            context,
            'Keskinleştirme',
            Icons.auto_fix_high,
            _sharpness,
            (value) {
              setState(() => _sharpness = value);
              controller.applyBeautySettings(
                whiteness: _whiteness,
                smoothness: _smoothness,
                sharpness: value,
                rosy: _rosy,
              );
            },
          ),
          const SizedBox(height: 24),
          _buildBeautySlider(
            context,
            'Gül Rengi',
            Icons.favorite,
            _rosy,
            (value) {
              setState(() => _rosy = value);
              controller.applyBeautySettings(
                whiteness: _whiteness,
                smoothness: _smoothness,
                sharpness: _sharpness,
                rosy: value,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMasksTab(BuildContext context, LivestreamScreenController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Face Lifting
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.face_retouching_natural, color: ColorRes.blueFollow),
                  const SizedBox(width: 8),
                  Text(
                    'Yüz Germe',
                    style: TextStyleCustom.unboundedMedium500(
                      color: blackPure(context),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _faceLiftingEnabled,
                onChanged: (value) {
                  setState(() => _faceLiftingEnabled = value);
                  controller.applyFaceLifting(
                    intensity: _faceLifting.toInt(),
                    enable: value,
                  );
                },
                activeColor: ColorRes.blueFollow,
              ),
            ],
          ),
          if (_faceLiftingEnabled) ...[
            const SizedBox(height: 16),
            _buildMaskSlider(
              context,
              _faceLifting,
              (value) {
                setState(() => _faceLifting = value);
                controller.applyFaceLifting(
                  intensity: value.toInt(),
                  enable: true,
                );
              },
            ),
          ],
          const SizedBox(height: 32),
          
          _buildMaskSliderWithLabel(
            context,
            'Büyük Gözler',
            Icons.visibility,
            _bigEyes,
            (value) {
              setState(() => _bigEyes = value);
              controller.applyBigEyes(value.toInt());
            },
          ),
          const SizedBox(height: 32),
          
          _buildMaskSliderWithLabel(
            context,
            'Kırışıklık Giderme',
            Icons.face,
            _wrinklesRemoving,
            (value) {
              setState(() => _wrinklesRemoving = value);
              controller.applyWrinklesRemoving(value.toInt());
            },
          ),
          const SizedBox(height: 32),
          
          _buildMaskSliderWithLabel(
            context,
            'Göz Altı Morluğu',
            Icons.remove_circle_outline,
            _darkCirclesRemoving,
            (value) {
              setState(() => _darkCirclesRemoving = value);
              controller.applyDarkCirclesRemoving(value.toInt());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPendantsTab(BuildContext context, LivestreamScreenController controller) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _pendants.length,
      itemBuilder: (context, index) {
        final pendant = _pendants[index];
        final isSelected = _selectedPendant == pendant.pendantName;

        return GestureDetector(
          onTap: () {
            setState(() {
              if (pendant.pendantName.isEmpty) {
                _selectedPendant = null;
              } else {
                _selectedPendant = pendant.pendantName;
              }
            });
            controller.applyPendant(pendant.pendantName);
            Get.back();
          },
          child: Container(
            decoration: BoxDecoration(
              color: bgLightGrey(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? ColorRes.blueFollow
                    : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: whitePure(context),
                    border: Border.all(
                      color: isSelected
                          ? ColorRes.blueFollow
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    pendant.icon,
                    color: isSelected
                        ? ColorRes.blueFollow
                        : textLightGrey(context),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    pendant.name,
                    style: TextStyleCustom.unboundedMedium500(
                      color: isSelected
                          ? ColorRes.blueFollow
                          : blackPure(context),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMakeupTab(BuildContext context, LivestreamScreenController controller) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _makeups.length,
      itemBuilder: (context, index) {
        final makeup = _makeups[index];
        final isSelected = _selectedMakeup == makeup.makeupName;

        return GestureDetector(
          onTap: () {
            setState(() {
              if (makeup.makeupName.isEmpty) {
                _selectedMakeup = null;
              } else {
                _selectedMakeup = makeup.makeupName;
              }
            });
            controller.applyMakeup(makeup.makeupName);
            Get.back();
          },
          child: Container(
            decoration: BoxDecoration(
              color: bgLightGrey(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? ColorRes.blueFollow
                    : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: whitePure(context),
                    border: Border.all(
                      color: isSelected
                          ? ColorRes.blueFollow
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    makeup.icon,
                    color: isSelected
                        ? ColorRes.blueFollow
                        : textLightGrey(context),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    makeup.name,
                    style: TextStyleCustom.unboundedMedium500(
                      color: isSelected
                          ? ColorRes.blueFollow
                          : blackPure(context),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBeautySlider(
    BuildContext context,
    String label,
    IconData icon,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: ColorRes.blueFollow, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyleCustom.unboundedMedium500(
                color: blackPure(context),
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Text(
              '${value.toInt()}',
              style: TextStyleCustom.unboundedMedium500(
                color: ColorRes.blueFollow,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Slider(
          value: value,
          min: 0,
          max: 100,
          divisions: 100,
          activeColor: ColorRes.blueFollow,
          inactiveColor: bgLightGrey(context),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildMaskSlider(
    BuildContext context,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Slider(
      value: value,
      min: 0,
      max: 100,
      divisions: 100,
      activeColor: ColorRes.blueFollow,
      inactiveColor: bgLightGrey(context),
      onChanged: onChanged,
    );
  }

  Widget _buildMaskSliderWithLabel(
    BuildContext context,
    String label,
    IconData icon,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: ColorRes.blueFollow, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyleCustom.unboundedMedium500(
                color: blackPure(context),
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Text(
              '${value.toInt()}',
              style: TextStyleCustom.unboundedMedium500(
                color: ColorRes.blueFollow,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Slider(
          value: value,
          min: 0,
          max: 100,
          divisions: 100,
          activeColor: ColorRes.blueFollow,
          inactiveColor: bgLightGrey(context),
          onChanged: onChanged,
        ),
      ],
    );
  }

  IconData _getFilterIcon(String filterName) {
    switch (filterName.toLowerCase()) {
      case 'natural':
        return Icons.eco;
      case 'warm':
        return Icons.wb_sunny;
      case 'cool':
        return Icons.ac_unit;
      case 'vintage':
        return Icons.camera_alt;
      case 'bright':
        return Icons.wb_incandescent;
      case 'night':
        return Icons.nightlight_round;
      default:
        return Icons.auto_awesome;
    }
  }
}
