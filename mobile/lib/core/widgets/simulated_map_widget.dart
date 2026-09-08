import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../data/services/location_service.dart';
import '../constants/api_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

// Geographic Coordinate Resolver for Ethiopian Locations (Addis Ababa focused)
class AddisAbabaLocations {
  static const LatLng center = LatLng(9.0108, 38.7617);
  static const LatLng userDefault = LatLng(8.9953, 38.7891); // Bole Medhanialem

  static const Map<String, LatLng> dictionary = {
    'bole': LatLng(8.9953, 38.7891),
    'bole medhanialem': LatLng(8.9953, 38.7891),
    'bole atlas': LatLng(9.0062, 38.7794),
    'bole bulbula': LatLng(8.9667, 38.7917),
    'kazanchis': LatLng(9.0185, 38.7696),
    'sarbet': LatLng(8.9920, 38.7360),
    'piassa': LatLng(9.0350, 38.7510),
    'piazza': LatLng(9.0350, 38.7510),
    'mexico': LatLng(9.0105, 38.7450),
    'megenagna': LatLng(9.0190, 38.7990),
    'cmc': LatLng(9.0210, 38.8350),
    'gerji': LatLng(8.9850, 38.8050),
    'ayat': LatLng(9.0280, 38.8650),
    'summit': LatLng(9.0130, 38.8520),
    'jemo': LatLng(8.9540, 38.7180),
    'lebu': LatLng(8.9680, 38.7290),
    'gotera': LatLng(8.9880, 38.7600),
    'lideta': LatLng(9.0080, 38.7380),
    'merkato': LatLng(9.0310, 38.7350),
    '4 kilo': LatLng(9.0340, 38.7630),
    '6 kilo': LatLng(9.0450, 38.7610),
    'tor hailoch': LatLng(9.0090, 38.7240),
    'kotebe': LatLng(9.0380, 38.8240),
    'jackros': LatLng(8.9980, 38.8220),
    'hayahulet': LatLng(9.0150, 38.7830),
    '22 mazoria': LatLng(9.0150, 38.7830),
  };

  static LatLng resolve(String locationName, {Offset? relativeFallback}) {
    final lower = locationName.toLowerCase().trim();
    for (final entry in dictionary.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    if (relativeFallback != null) {
      // Map normalized 0.0..1.0 bounding box to Addis Ababa Lat/Lng
      final lat = 9.045 - (relativeFallback.dy * 0.08);
      final lng = 38.725 + (relativeFallback.dx * 0.12);
      return LatLng(lat, lng);
    }
    return center;
  }

  static String resolveName(LatLng coords) {
    double minDistance = double.infinity;
    String closest = 'Addis Ababa';
    for (final entry in dictionary.entries) {
      final dLat = coords.latitude - entry.value.latitude;
      final dLng = coords.longitude - entry.value.longitude;
      final dist = (dLat * dLat) + (dLng * dLng);
      if (dist < minDistance) {
        minDistance = dist;
        closest = entry.key
            .split(' ')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ');
      }
    }
    return '$closest, Addis Ababa';
  }
}

class MapTaskPin {
  final String id;
  final String title;
  final String price;
  final Offset relativePosition; // 0.0 to 1.0 (backward compatibility)
  final String location;
  final LatLng? coordinates;
  final String? category;

  MapTaskPin({
    required this.id,
    required this.title,
    required this.price,
    required this.relativePosition,
    required this.location,
    this.coordinates,
    this.category,
  });

  LatLng get resolvedCoordinates =>
      coordinates ?? AddisAbabaLocations.resolve(location, relativeFallback: relativePosition);
}

// Aliased as RealtimeMapWidget for clean semantic imports
typedef RealtimeMapWidget = SimulatedMapWidget;

class SimulatedMapWidget extends StatefulWidget {
  final List<MapTaskPin> pins;
  final Function(MapTaskPin)? onPinSelected;
  final LatLng? initialCenter;
  final double initialZoom;
  final bool showControls;
  final bool showUserLocation;
  final bool enableRoutePolyline;
  final bool showFullScreenBtn;
  final VoidCallback? onFullScreenTap;

  const SimulatedMapWidget({
    super.key,
    required this.pins,
    this.onPinSelected,
    this.initialCenter,
    this.initialZoom = 13.5,
    this.showControls = true,
    this.showUserLocation = true,
    this.enableRoutePolyline = true,
    this.showFullScreenBtn = true,
    this.onFullScreenTap,
  });

  @override
  State<SimulatedMapWidget> createState() => _SimulatedMapWidgetState();
}

class _SimulatedMapWidgetState extends State<SimulatedMapWidget> with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;

  String? _selectedPinId;
  String _activeMapStyle = 'm'; // 'm' (Roads), 'y' (Hybrid Satellite), 'p' (Terrain)
  bool _tileLoadError = false;
  LatLng _userDeviceLocation = AddisAbabaLocations.userDefault;
  StreamSubscription<LatLng>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _initRealTimeLocation();
  }

  void _initRealTimeLocation() async {
    final pos = await LocationService().getCurrentDeviceLocation();
    if (pos != null && mounted) {
      setState(() {
        _userDeviceLocation = pos;
      });
    }
    _locationSubscription = LocationService().realTimeLocationStream.listen((realPos) {
      if (mounted) {
        setState(() {
          _userDeviceLocation = realPos;
        });
      }
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  LatLng get _effectiveCenter {
    if (widget.initialCenter != null) return widget.initialCenter!;
    if (widget.pins.isNotEmpty) {
      return widget.pins.first.resolvedCoordinates;
    }
    return _userDeviceLocation;
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1.0);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, (currentZoom - 1.0).clamp(4.0, 19.0));
  }

  void _recenter() async {
    final current = await LocationService().getCurrentDeviceLocation() ?? _userDeviceLocation;
    _mapController.move(current, 15.0);
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

  void _openFullScreenMap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textDark,
            elevation: 1,
            title: Text(
              'Real-Time Live Map',
              style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.close_fullscreen_rounded, color: AppColors.textDark),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          body: SimulatedMapWidget(
            pins: widget.pins,
            onPinSelected: widget.onPinSelected,
            initialCenter: _mapController.camera.center,
            initialZoom: _mapController.camera.zoom,
            showControls: true,
            showUserLocation: widget.showUserLocation,
            enableRoutePolyline: widget.enableRoutePolyline,
            showFullScreenBtn: false,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMultiplePins = widget.pins.length >= 2;
    final polylinePoints = hasMultiplePins && widget.enableRoutePolyline
        ? widget.pins.map((p) => p.resolvedCoordinates).toList()
        : <LatLng>[];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // 1. Live FlutterMap with MapTiler Real-Time Cloud Tiles
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _effectiveCenter,
              initialZoom: widget.initialZoom,
              minZoom: 5.0,
              maxZoom: 19.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // Google Maps Real-Time Tile Layer (with automatic MapTiler & OSM fallbacks)
              TileLayer(
                urlTemplate: _tileLoadError
                    ? ApiConstants.mapTilerTileUrl(style: 'streets-v2')
                    : ApiConstants.googleMapTileUrl(style: _activeMapStyle),
                fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.finish.app.mobile',
                maxZoom: 20,
                errorTileCallback: (_, __, ___) {
                  if (!_tileLoadError && mounted) {
                    setState(() => _tileLoadError = true);
                  }
                },
              ),

              // Navigation Route Polyline (if route between 2+ points)
              if (polylinePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    // Outer glow border
                    Polyline(
                      points: polylinePoints,
                      color: Colors.white.withOpacity(0.9),
                      strokeWidth: 6.0,
                    ),
                    // Inner emerald route line
                    Polyline(
                      points: polylinePoints,
                      color: AppColors.primary,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),

              // Interactive Real-Time Markers Layer
              MarkerLayer(
                markers: [
                  // Live User Location Marker (Pulsating Blue Radar)
                  if (widget.showUserLocation)
                    Marker(
                      point: _userDeviceLocation,
                      width: 50,
                      height: 50,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          return _buildUserRadarMarker(_pulseController.value);
                        },
                      ),
                    ),

                  // Task Price & Location Pins
                  for (final pin in widget.pins)
                    Marker(
                      point: pin.resolvedCoordinates,
                      width: 110,
                      height: 55,
                      alignment: Alignment.center,
                      child: _buildInteractivePin(pin),
                    ),
                ],
              ),
            ],
          ),

          // 2. Map Floating Overlays & Controls
          if (widget.showControls) ...[
            // Top Left: Full Screen Toggle Button
            if (widget.showFullScreenBtn)
              Positioned(
                top: 12,
                left: 12,
                child: GestureDetector(
                  onTap: () {
                    if (widget.onFullScreenTap != null) {
                      widget.onFullScreenTap!();
                    } else {
                      _openFullScreenMap(context);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fullscreen_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Full Screen',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Top Right: Style Switcher Badge (Streets / Outdoor / Satellite)
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: _toggleMapStyle,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _activeMapStyle == 'y'
                            ? Icons.satellite_alt_rounded
                            : (_activeMapStyle == 'p' ? Icons.terrain_rounded : Icons.map_rounded),
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _activeMapStyle == 'y'
                            ? 'Satellite'
                            : (_activeMapStyle == 'p' ? 'Terrain' : 'Google Roads'),
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Right: Zoom & Recenter Controls
            Positioned(
              bottom: 12,
              right: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Recenter to user FAB
                  _buildMapControlBtn(
                    icon: Icons.my_location_rounded,
                    iconColor: AppColors.primary,
                    onTap: _recenter,
                  ),
                  const SizedBox(height: 6),
                  // Zoom In FAB
                  _buildMapControlBtn(
                    icon: Icons.add_rounded,
                    iconColor: AppColors.textDark,
                    onTap: _zoomIn,
                  ),
                  const SizedBox(height: 4),
                  // Zoom Out FAB
                  _buildMapControlBtn(
                    icon: Icons.remove_rounded,
                    iconColor: AppColors.textDark,
                    onTap: _zoomOut,
                  ),
                ],
              ),
            ),

            // Bottom Left: Google Maps Attribution Pill
            Positioned(
              bottom: 8,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Google Maps © 2026',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Interactive Task Pin Marker
  Widget _buildInteractivePin(MapTaskPin pin) {
    final isSelected = _selectedPinId == pin.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPinId = pin.id;
        });
        _mapController.move(pin.resolvedCoordinates, _mapController.camera.zoom);
        if (widget.onPinSelected != null) {
          widget.onPinSelected!(pin);
        }
      },
      child: AnimatedScale(
        scale: isSelected ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0F172A) : AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF34D399) : Colors.white,
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? const Color(0xFF10B981).withOpacity(0.5)
                        : Colors.black.withOpacity(0.28),
                    blurRadius: isSelected ? 12 : 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.place_rounded,
                    size: 13,
                    color: isSelected ? const Color(0xFF34D399) : Colors.white,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    pin.price,
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Pin stem notch
            CustomPaint(
              size: const Size(10, 5),
              painter: _TrianglePainter(
                color: isSelected ? const Color(0xFF0F172A) : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Pulsating Radar User Location Marker
  Widget _buildUserRadarMarker(double pulse) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Expanding Radar Ring
        Container(
          width: 20 + (pulse * 30),
          height: 20 + (pulse * 30),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF3B82F6).withOpacity((1.0 - pulse) * 0.4),
          ),
        ),
        // Outer Solid Halo
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF3B82F6).withOpacity(0.25),
          ),
        ),
        // Core Dot
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2563EB),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Floating Control Button Helper
  Widget _buildMapControlBtn({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black38,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }
}

// Pin bottom notch triangle
class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) => oldDelegate.color != color;
}
