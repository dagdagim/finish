import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/simulated_map_widget.dart';
import '../../data/services/location_service.dart';

class LocationPickerResult {
  final String address;
  final LatLng coordinates;
  final String? unitNotes;

  LocationPickerResult({
    required this.address,
    required this.coordinates,
    this.unitNotes,
  });
}

class LocationPickerScreen extends StatefulWidget {
  final String title;
  final String? initialAddress;
  final LatLng? initialCoordinates;
  final bool isDropoff;

  const LocationPickerScreen({
    super.key,
    this.title = 'Select Location on Map',
    this.initialAddress,
    this.initialCoordinates,
    this.isDropoff = false,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final TextEditingController _searchController;
  late final TextEditingController _unitController;
  late final AnimationController _pinAnimController;

  late LatLng _currentCenter;
  String _detectedAddress = 'Bole Medhanialem, Addis Ababa';
  String _activeMapStyle = 'm'; // 'm' (Roads), 'y' (Hybrid Satellite), 'p' (Terrain)
  bool _isDragging = false;
  bool _showSearchSuggestions = false;

  // Curated Addis Ababa Landmarks for Quick Search
  static const List<Map<String, dynamic>> _popularLandmarks = [
    {'name': 'Bole Medhanialem', 'area': 'Bole Sub-City', 'coords': LatLng(8.9953, 38.7891), 'icon': Icons.church_rounded},
    {'name': 'Edna Mall & Cinema', 'area': 'Bole, Cameroon St', 'coords': LatLng(8.9968, 38.7877), 'icon': Icons.movie_filter_rounded},
    {'name': 'Kazanchis Business Center', 'area': 'Kirkos Sub-City', 'coords': LatLng(9.0185, 38.7696), 'icon': Icons.business_rounded},
    {'name': 'Bole International Airport (T2)', 'area': 'Bole Airport', 'coords': LatLng(8.9806, 38.7994), 'icon': Icons.flight_rounded},
    {'name': 'Sarbet (Near Canadian Embassy)', 'area': 'Nifas Silk Sub-City', 'coords': LatLng(8.9920, 38.7360), 'icon': Icons.apartment_rounded},
    {'name': 'Piassa (De Gaulle Square)', 'area': 'Arada Sub-City', 'coords': LatLng(9.0350, 38.7510), 'icon': Icons.storefront_rounded},
    {'name': 'Mexico Square (LRT Station)', 'area': 'Lideta Sub-City', 'coords': LatLng(9.0105, 38.7450), 'icon': Icons.directions_subway_rounded},
    {'name': 'CMC Michael Church', 'area': 'Yeka Sub-City', 'coords': LatLng(9.0210, 38.8350), 'icon': Icons.location_city_rounded},
    {'name': 'Megenagna Roundabout', 'area': 'Yeka / Bole Border', 'coords': LatLng(9.0190, 38.7990), 'icon': Icons.traffic_rounded},
    {'name': 'Gerji Imperial', 'area': 'Bole Sub-City', 'coords': LatLng(8.9850, 38.8050), 'icon': Icons.home_work_rounded},
    {'name': 'Ayat Square & Zone 3', 'area': 'Yeka Sub-City', 'coords': LatLng(9.0280, 38.8650), 'icon': Icons.villa_rounded},
    {'name': 'Gotera Interchange', 'area': 'Kirkos Sub-City', 'coords': LatLng(8.9880, 38.7600), 'icon': Icons.alt_route_rounded},
    {'name': 'Merkato Market Center', 'area': 'Addis Ketema', 'coords': LatLng(9.0310, 38.7350), 'icon': Icons.shopping_basket_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _searchController = TextEditingController();
    _unitController = TextEditingController();

    // Determine initial center
    if (widget.initialCoordinates != null) {
      _currentCenter = widget.initialCoordinates!;
      _updateAddressFromCoords(_currentCenter);
    } else if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _currentCenter = AddisAbabaLocations.resolve(widget.initialAddress!);
      _detectedAddress = widget.initialAddress!;
    } else {
      _currentCenter = AddisAbabaLocations.userDefault;
      _detectInitialDeviceLocation();
    }

    _pinAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  void _detectInitialDeviceLocation() async {
    final realPos = await LocationService().getCurrentDeviceLocation();
    if (realPos != null && mounted) {
      setState(() {
        _currentCenter = realPos;
      });
      _mapController.move(realPos, 15.5);
      final realAddr = await LocationService().reverseGeocode(realPos);
      if (mounted) {
        setState(() {
          _detectedAddress = realAddr;
        });
      }
    } else {
      _updateAddressFromCoords(_currentCenter);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _unitController.dispose();
    _pinAnimController.dispose();
    super.dispose();
  }

  // Reverse geocoding using LocationService with local fallback
  void _updateAddressFromCoords(LatLng target) async {
    final addr = await LocationService().reverseGeocode(target);
    if (mounted) {
      setState(() {
        _detectedAddress = addr;
      });
    }
  }

  void _moveToLocation(LatLng target, {String? name}) {
    setState(() {
      _currentCenter = target;
      if (name != null) {
        _detectedAddress = name;
      } else {
        _updateAddressFromCoords(target);
      }
      _showSearchSuggestions = false;
    });
    _mapController.move(target, 15.5);
  }

  void _useMyRealLocation() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 10),
            Text('Acquiring real device GPS location...'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 1),
      ),
    );

    final realPos = await LocationService().getCurrentDeviceLocation();
    if (realPos != null) {
      _moveToLocation(realPos);
      final realAddr = await LocationService().reverseGeocode(realPos);
      if (mounted) {
        setState(() {
          _detectedAddress = realAddr;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.gps_fixed_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('Located at $realAddr')),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _toggleMapStyle() {
    setState(() {
      if (_activeMapStyle == 'm') {
        _activeMapStyle = 'y'; // Hybrid Satellite
      } else if (_activeMapStyle == 'y') {
        _activeMapStyle = 'p'; // Terrain
      } else {
        _activeMapStyle = 'm'; // Standard Road
      }
    });
  }

  void _confirmSelection() {
    final result = LocationPickerResult(
      address: _detectedAddress,
      coordinates: _currentCenter,
      unitNotes: _unitController.text.trim().isNotEmpty ? _unitController.text.trim() : null,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final isDropoff = widget.isDropoff;
    final pinColor = isDropoff ? const Color(0xFFEF4444) : AppColors.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Full-Screen Live Google Maps
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 14.5,
              minZoom: 5.0,
              maxZoom: 20.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  _currentCenter = position.center;
                  if (!_isDragging) {
                    setState(() => _isDragging = true);
                    _pinAnimController.forward();
                  }
                }
              },
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  if (_isDragging) {
                    setState(() => _isDragging = false);
                    _pinAnimController.reverse();
                    _updateAddressFromCoords(_currentCenter);
                  }
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: ApiConstants.googleMapTileUrl(style: _activeMapStyle),
                userAgentPackageName: 'com.finish.app.mobile',
                maxZoom: 20,
              ),

              // User location pulsating radar marker
              MarkerLayer(
                markers: [
                  Marker(
                    point: AddisAbabaLocations.userDefault,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2563EB).withOpacity(0.25),
                      ),
                      child: Center(
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF2563EB),
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. Center Interactive Target Pin (Fixed in Center with Drop Animation)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 38),
                  child: AnimatedBuilder(
                    animation: _pinAnimController,
                    builder: (context, child) {
                      final lift = _pinAnimController.value * -14.0;
                      return Transform.translate(
                        offset: Offset(0, lift),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Glowing location callout badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDropoff ? const Color(0xFF991B1B) : const Color(0xFF064E3B),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isDropoff ? Icons.location_on_rounded : Icons.trip_origin_rounded,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isDropoff ? 'Set Destination' : 'Set Pickup',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Large 3D Pin Icon
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.location_pin,
                                  size: 46,
                                  color: pinColor,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                const Positioned(
                                  top: 9,
                                  child: Icon(Icons.circle, size: 14, color: Colors.white),
                                ),
                              ],
                            ),
                            // Ground shadow circle below pin
                            Container(
                              width: 14 + (_pinAnimController.value * 6),
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.35 - (_pinAnimController.value * 0.15)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // 3. Top Floating Search & Navigation Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Row: Back button + Search bar + Style Switcher
                  Row(
                    children: [
                      // Back Button
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 4,
                        shadowColor: Colors.black26,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.of(context).pop(),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.textDark),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Search Input Box
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: AppTypography.titleSmall.copyWith(fontSize: 13.5),
                            onTap: () => setState(() => _showSearchSuggestions = true),
                            onChanged: (val) => setState(() => _showSearchSuggestions = true),
                            decoration: InputDecoration(
                              hintText: 'Search place, road, or landmark in Addis',
                              hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted, fontSize: 12.5),
                              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 16),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Map Style Switcher (Streets / Satellite / Terrain)
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 4,
                        shadowColor: Colors.black26,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _toggleMapStyle,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              _activeMapStyle == 'y'
                                  ? Icons.satellite_alt_rounded
                                  : (_activeMapStyle == 'p' ? Icons.terrain_rounded : Icons.layers_rounded),
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Search Suggestions Overlay List
                  if (_showSearchSuggestions) ...[
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 250),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        children: _filteredLandmarks.map((item) {
                          return ListTile(
                            dense: true,
                            leading: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(item['icon'] as IconData, size: 15, color: AppColors.primary),
                            ),
                            title: Text(
                              item['name'] as String,
                              style: AppTypography.titleSmall.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              item['area'] as String,
                              style: AppTypography.labelMedium.copyWith(fontSize: 11, color: AppColors.textMuted),
                            ),
                            onTap: () {
                              _searchController.text = item['name'] as String;
                              _moveToLocation(item['coords'] as LatLng, name: '${item['name']}, ${item['area']}');
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 4. Quick Landmark Pill Bar (Horizontal scroll under search)
          if (!_showSearchSuggestions)
            Positioned(
              top: 115,
              left: 0,
              right: 0,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    // Real Location Pill
                    _buildLandmarkChip(
                      icon: Icons.my_location_rounded,
                      label: 'My Real Location',
                      isHighlight: true,
                      onTap: _useMyRealLocation,
                    ),
                    for (final lm in _popularLandmarks.take(6))
                      _buildLandmarkChip(
                        icon: lm['icon'] as IconData,
                        label: lm['name'] as String,
                        isHighlight: false,
                        onTap: () => _moveToLocation(lm['coords'] as LatLng, name: '${lm['name']}, ${lm['area']}'),
                      ),
                  ],
                ),
              ),
            ),

          // 5. Floating Real Location & Recenter Action Buttons (Right side)
          Positioned(
            right: 16,
            bottom: 235,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Real GPS Location Button
                Material(
                  color: AppColors.primary,
                  shape: const CircleBorder(),
                  elevation: 5,
                  shadowColor: AppColors.primary.withOpacity(0.5),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _useMyRealLocation,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.my_location_rounded, size: 22, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Zoom In
                _buildMapControlBtn(
                  icon: Icons.add_rounded,
                  onTap: () => _mapController.move(_currentCenter, _mapController.camera.zoom + 1.0),
                ),
                const SizedBox(height: 6),

                // Zoom Out
                _buildMapControlBtn(
                  icon: Icons.remove_rounded,
                  onTap: () => _mapController.move(_currentCenter, _mapController.camera.zoom - 1.0),
                ),
              ],
            ),
          ),

          // 6. Bottom Confirmation & Address Detail Sheet
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Location Type Indicator
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDropoff ? const Color(0xFFFEE2E2) : AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isDropoff ? Icons.location_on_rounded : Icons.trip_origin_rounded,
                          size: 16,
                          color: pinColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDropoff ? 'SELECTED DROP-OFF DESTINATION' : 'SELECTED PICKUP LOCATION',
                              style: AppTypography.labelMedium.copyWith(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: pinColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _detectedAddress,
                              style: AppTypography.titleMedium.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Optional unit / building notes input
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: TextField(
                      controller: _unitController,
                      style: AppTypography.bodyMedium.copyWith(fontSize: 12.5),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        icon: const Icon(Icons.apartment_rounded, size: 16, color: AppColors.textMuted),
                        hintText: 'Building, house number, or gate notes (optional)',
                        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Big Confirm Location Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _confirmSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pinColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Confirm This Place',
                            style: AppTypography.titleSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredLandmarks {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _popularLandmarks;
    return _popularLandmarks.where((item) {
      final name = (item['name'] as String).toLowerCase();
      final area = (item['area'] as String).toLowerCase();
      return name.contains(query) || area.contains(query);
    }).toList();
  }

  Widget _buildLandmarkChip({
    required IconData icon,
    required String label,
    required bool isHighlight,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isHighlight ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 3,
        shadowColor: Colors.black26,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: isHighlight ? Colors.white : AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: isHighlight ? Colors.white : AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapControlBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: AppColors.textDark),
        ),
      ),
    );
  }
}
