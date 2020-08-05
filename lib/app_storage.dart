import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:localstorage/localstorage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'place.dart';

class AppStorage {
  static LocalStorage storage = LocalStorage('harvest_places');
  static SharedPreferences prefs;

  static List<Place> listPlaces;

  static List listToJson() {
    List list = listPlaces.map((item) => item.toJson()).toList();
    return list;
  }

  static void setPlaces(List<Place> places) {
    listPlaces = places;
  }

  static Future<List<Place>> getFromStorage() async {
    await storage.ready;
    final items = await storage.getItem('places') as List;
    if (items == null) {
      return [];
    }

    return items
        .cast<Map<String, dynamic>>()
        .map((item) => Place.fromJson(item))
        .toList();
  }

  static Future<void> saveToStorage() async {
    await storage.setItem('places', listToJson());
  }

  Future<void> clearStorage() async {
    await storage.clear();
  }

  static Future<bool> isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final firstRun = prefs.getInt('first_run') ?? 1;
    return firstRun == 1;
  }

  static Future<void> unsetFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('first_run', 0);
  }

  static Future<bool> isRegisteredNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final isReg = prefs.getBool('registered_notification') ?? false;
    return isReg;
  }

  static Future<void> setRegisteredNotification() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('registered_notification', true);
  }

  static Future<bool> isRunNotification(bool morning) async {
    var notificationType =
        morning ? 'morning_notification' : 'evening_notificaion';
    final prefs = await SharedPreferences.getInstance();
    final isReg = prefs.getBool(notificationType) ?? false;
    return isReg;
  }

  static Future<void> setRunNotification(bool morning, bool isSet) async {
    var notificationType =
        morning ? 'morning_notification' : 'evening_notificaion';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(notificationType, isSet);
  }

  static Future<bool> isSigned() async {
    final prefs = await SharedPreferences.getInstance();
    final isSign = prefs.getBool('google_sign') ?? false;
    return isSign;
  }

  static Future<void> setSign(bool signed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('google_sign', signed);
  }

  static Future<void> setLatLng(LatLng lng) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('longitude', lng.longitude);
    prefs.setDouble('latitude', lng.latitude);
  }

  static Future<LatLng> getLatLng() async {
    final prefs = await SharedPreferences.getInstance();
    var lng = prefs.getDouble('longitude') ?? 37.8136;
    var lat = prefs.getDouble('latitude') ?? -144.9631;
    return LatLng(lat, lng);
  }
}
