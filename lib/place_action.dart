import 'dart:math';

import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_storage.dart';
import 'place.dart';

class PlaceAction {
  static Future<void> onSendEmail(List<Place> _selectedPlaces) async {
    var emailText = StringBuffer();
    emailText.write('Places: ${_selectedPlaces.length}\n');
    var list = _selectedPlaces.toList();
    list.forEach((place) {
      var index = list.indexOf(place) + 1;
      var plText = 'Place ${index}: \n';
      plText += 'Address: ${place.address}\n';
      plText += 'Location: (${place.latitude}, ${place.longitude})\n';
      plText += 'Number of Trees: ${place.countTrees}\n';
      plText += 'Last Harvest Date: ${place.lastDate}\n';
      plText += 'Ready for Harvest Date: ${place.readyDate}\n\n';
      emailText.write(plText);
    });
    var content = emailText.toString();
    final email = Email(
      body: content,
      subject: 'Harvest Places Info - ' +
          DateFormat('dd/MM/yyyy').format(DateTime.now()),
      recipients: ['alexmoorhouse@gmail.com'],
      attachmentPaths: [],
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email);
    } catch (error) {}
  }

  static Future<LatLng> getCurrentLocation() async {
    var location = Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return await AppStorage.getLatLng();
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return await AppStorage.getLatLng();
      }
    }

    var position = await geo.Geolocator()
        .getCurrentPosition(desiredAccuracy: geo.LocationAccuracy.high);
    return LatLng(position.latitude, position.longitude);
  }

  static double distance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  static Future<void> onNavigate(List<Place> _selectedPlaces) async {
    assert(_selectedPlaces.isNotEmpty);
    var navPlaces = _selectedPlaces.toList();
    var position = await getCurrentLocation();
    navPlaces.sort((a, b) {
      return distance(
              a.latitude, a.longitude, position.latitude, position.longitude)
          .compareTo(distance(
              b.latitude, b.longitude, position.latitude, position.longitude));
    });
    var origin = navPlaces.first;
    var destination = navPlaces.last;
    var url =
        'https://www.google.com/maps/dir/?api=1&origin=${position.latitude},${position.longitude}';
    url += '&destination=${destination.latitude},${destination.longitude}';
    var waypoints = '';
    for (var pl in navPlaces) {
      if (pl == destination) {
        continue;
      }
      if (waypoints == '') {
        waypoints += '&waypoints=${pl.latitude},${pl.longitude}';
      } else {
        waypoints += '|${pl.latitude},${pl.longitude}';
      }
    }
    url += waypoints + '&dir_action=navigate';
    await _launchURL(url);
  }

  static Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  static Future<List<Place>> getHarvestPlaces() async {
    var plList = await AppStorage.getFromStorage();
    var now = DateTime.now();
    var today = DateFormat('dd/MM/yyyy').format(now);
    var tmrw = DateFormat('dd/MM/yyyy').format(now.add(Duration(days: 1)));
    var places = <Place>[];

    for (var place in plList) {
      var readyDate = DateFormat('dd/MM/yyyy').parse(place.readyDate);
      if (now.hour >= 20 &&
          now.hour < 5 &&
          (place.readyDate == tmrw || readyDate.isBefore(now))) {
        places.add(place);
      }
      if (now.hour >= 5 &&
          now.hour <= 19 &&
          (place.readyDate == today || readyDate.isBefore(now))) {
        places.add(place);
      }
    }
    AppStorage.setRunNotification(true, false);
    AppStorage.setRunNotification(false, false);
    return places;
  }

  static Future<void> onSendEmailAction() async {
    var places = await getHarvestPlaces();
    await onSendEmail(places);
  }

  static Future<void> onNavigationAction() async {
    var places = await getHarvestPlaces();
    await onNavigate(places);
  }
}
