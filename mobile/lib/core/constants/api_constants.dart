import 'package:flutter/foundation.dart';

class ApiConstants {
  static String _activeBaseUrl = '';

  static const String liveRenderBaseUrl = 'https://finish-backend-lyr3.onrender.com/api/v1';

  static List<String> get candidateHosts {
    if (kIsWeb) {
      return const [
        'https://finish-backend-lyr3.onrender.com/api/v1',
        'http://127.0.0.1:5000/api/v1',
        'http://localhost:5000/api/v1',
      ];
    }
    return const [
      'https://finish-backend-lyr3.onrender.com/api/v1',
      'http://127.0.0.1:5000/api/v1',       // Works with adb reverse & local
      'http://10.180.63.219:5000/api/v1',    // Local Wi-Fi network IP
      'http://10.0.2.2:5000/api/v1',        // Android Emulator
      'http://localhost:5000/api/v1',
    ];
  }

  static String get baseUrl {
    if (_activeBaseUrl.isNotEmpty) {
      return _activeBaseUrl;
    }
    return liveRenderBaseUrl;
  }

  static void setActiveBaseUrl(String url) {
    _activeBaseUrl = url;
  }

  // Endpoints
  static const String signup = '/auth/signup';
  static const String login = '/auth/login';
  static const String googleSendOtp = '/auth/google/send-otp';
  static const String googleVerifyOtp = '/auth/google/verify-otp';
  static const String getMe = '/users/me';
  static const String switchMode = '/users/mode';
  static const String verification = '/users/verification';
  static const String tasks = '/tasks';
  static const String taskFeed = '/tasks/feed';
  static const String wallet = '/wallet';
  static const String withdraw = '/wallet/withdraw';
  static const String conversations = '/conversations';
  static const String adminStats = '/admin/stats';
  static const String adminUsers = '/admin/users';
  static const String adminTasks = '/admin/tasks';
  static const String adminDisputes = '/admin/disputes';
  static const String adminBroadcast = '/admin/broadcast';

  // Google Maps API Key & Tile URLs
  static const String googleMapApiKey = 'AIzaSyAhTRToocH8vgbikoSixChTVK5BKnl8PkA';
  
  // Google Maps Raster Tiles
  static String googleMapTileUrl({String style = 'm'}) {
    // style: 'm' (Standard Road), 's' (Satellite), 'y' (Hybrid Satellite + Road labels), 'p' (Terrain)
    return 'https://mt1.google.com/vt/lyrs=$style&hl=en&x={x}&y={y}&z={z}&key=$googleMapApiKey';
  }
  static String googleMapRoadTileUrl = 'https://mt1.google.com/vt/lyrs=m&hl=en&x={x}&y={y}&z={z}&key=$googleMapApiKey';
  static String googleMapSatelliteTileUrl = 'https://mt1.google.com/vt/lyrs=s&hl=en&x={x}&y={y}&z={z}&key=$googleMapApiKey';
  static String googleMapHybridTileUrl = 'https://mt1.google.com/vt/lyrs=y&hl=en&x={x}&y={y}&z={z}&key=$googleMapApiKey';
  static String googleMapTerrainTileUrl = 'https://mt1.google.com/vt/lyrs=p&hl=en&x={x}&y={y}&z={z}&key=$googleMapApiKey';

  // Fallback MapTiler Real-Time Map Configuration
  static const String mapTilerApiKey = 'xadeN1n0hEdTh3OK83PU';
  static String mapTilerTileUrl({String style = 'streets-v2'}) =>
      'https://api.maptiler.com/maps/$style/{z}/{x}/{y}.png?key=$mapTilerApiKey';
  static String mapTilerSatelliteTileUrl =
      'https://api.maptiler.com/maps/hybrid/{z}/{x}/{y}.jpg?key=$mapTilerApiKey';
}
