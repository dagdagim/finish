import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' hide Path;
import '../../core/constants/api_constants.dart';
import '../../core/widgets/simulated_map_widget.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  LatLng? _lastKnownLocation;
  LatLng? get lastKnownLocation => _lastKnownLocation;

  // Check and request location permission from the device
  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are disabled on the device
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Get current real-time GPS position from device hardware
  Future<LatLng?> getCurrentDeviceLocation() async {
    try {
      final hasPermission = await handleLocationPermission();
      if (!hasPermission) {
        // Fallback to last known or Addis Ababa default if permission is not granted
        return _lastKnownLocation ?? AddisAbabaLocations.userDefault;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final realCoords = LatLng(position.latitude, position.longitude);
      _lastKnownLocation = realCoords;
      return realCoords;
    } catch (e) {
      debugPrint('Error getting real device GPS location: $e');
      // If error occurs, try last known position
      try {
        final lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null) {
          final coords = LatLng(lastPos.latitude, lastPos.longitude);
          _lastKnownLocation = coords;
          return coords;
        }
      } catch (_) {}
      return _lastKnownLocation ?? AddisAbabaLocations.userDefault;
    }
  }

  // Stream of continuous live location updates
  Stream<LatLng> get realTimeLocationStream {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters moved
      ),
    ).map((pos) {
      final coords = LatLng(pos.latitude, pos.longitude);
      _lastKnownLocation = coords;
      return coords;
    });
  }

  // Reverse geocode real coordinates to a human-readable street/area address
  Future<String> reverseGeocode(LatLng coords) async {
    try {
      // 1. Try Native Device Geocoding
      final placemarks = await placemarkFromCoordinates(
        coords.latitude,
        coords.longitude,
      ).timeout(const Duration(seconds: 4));

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[];

        if (place.street != null && place.street!.isNotEmpty && !place.street!.contains('+')) {
          parts.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          parts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        } else if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
          parts.add(place.subAdministrativeArea!);
        }

        if (parts.isNotEmpty) {
          return parts.join(', ');
        }
      }
    } catch (_) {}

    // 2. Try Google Maps Geocoding API with provided Google Maps Key
    try {
      final googleUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${coords.latitude},${coords.longitude}&key=${ApiConstants.googleMapApiKey}',
      );
      final response = await http.get(googleUrl).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['results'] is List && (data['results'] as List).isNotEmpty) {
          final formattedAddress = data['results'][0]['formatted_address'] as String?;
          if (formattedAddress != null && formattedAddress.isNotEmpty) {
            return formattedAddress;
          }
        }
      }
    } catch (_) {}

    // 3. Try MapTiler Geocoding API if Google/Native fails
    try {
      final url = Uri.parse(
        'https://api.maptiler.com/geocoding/${coords.longitude},${coords.latitude}.json?key=${ApiConstants.mapTilerApiKey}',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['features'] is List && (data['features'] as List).isNotEmpty) {
          final feature = data['features'][0];
          final placeName = feature['place_name'] as String?;
          if (placeName != null && placeName.isNotEmpty) {
            return placeName;
          }
        }
      }
    } catch (_) {}

    // 4. Fallback to closest known landmark in Addis Ababa
    return AddisAbabaLocations.resolveName(coords);
  }
}
