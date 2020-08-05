import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'app_notification.dart';
import 'app_storage.dart';
import 'google_drive_task.dart';
import 'harvest_tracker_app.dart';
import 'place.dart';
import 'place_action.dart';
import 'place_details.dart';

class PlaceMap extends StatefulWidget {
  const PlaceMap({
    Key key,
    this.center,
  }) : super(key: key);

  final LatLng center;

  @override
  PlaceMapState createState() => PlaceMapState();
}

class PlaceMapState extends State<PlaceMap> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      notificationInitialize(context);
    });
  }

  @override
  void dispose() {
    didReceiveLocalNotificationSubject.close();
    selectNotificationSubject.close();
    super.dispose();
  }

  static Future<BitmapDescriptor> _getPlaceMarkerIcon(
      BuildContext context, Place place, bool selected) async {
    var markerIcon = 'assets/tree';
    var isFull = false;

    if (place.readyDate.isNotEmpty) {
      var readyDate = DateFormat('dd/MM/yyyy').parse(place.readyDate);
      isFull = readyDate.isBefore(DateTime.now());
    }

    if (place.countTrees == 1) {
      if (isFull) {
        markerIcon = 'assets/tree1';
      } else {
        markerIcon = 'assets/tree1_';
      }
    } else if (place.countTrees > 1 && place.countTrees < 4) {
      if (isFull) {
        markerIcon = 'assets/tree3';
      } else {
        markerIcon = 'assets/tree3_';
      }
    } else if (place.countTrees > 3) {
      if (isFull) {
        markerIcon = 'assets/tree4';
      } else {
        markerIcon = 'assets/tree4_';
      }
    }
    if (selected) {
      markerIcon += 'hover.png';
    } else {
      markerIcon += '.png';
    }

    return BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(48, 48)), markerIcon);
  }

  /* static List<Place> _getPlacesForCategory(PlaceCategory category, List<Place> places) {
    return places.where((place) => place.category == category).toList();
  } */

  Completer<GoogleMapController> mapController = Completer();

  MapType _currentMapType = MapType.normal;

  LatLng _lastMapPosition;
  final Set<Place> _selectedPlaces = {};

  final Map<Marker, Place> _markedPlaces = <Marker, Place>{};

  final Set<Marker> _markers = {};
  final Set<Timer> _markerTimers = {};

  Marker _pendingMarker;

  MapConfiguration _configuration;

  Future<void> onMapCreated(GoogleMapController controller) async {
    mapController.complete(controller);
    _lastMapPosition = widget.center;
    await _mapUpdate();
    _firstRun();
    runNotification();
  }

  Future<void> runNotification() async {
    if (await AppStorage.isRunNotification(true) ||
        await AppStorage.isRunNotification(false)) {
      await showDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text('Confirm'),
          content: Text('Please select Navigation or Send Email'),
          actions: [
            CupertinoDialogAction(
              child: Text('Navigate'),
              onPressed: () async {
                await PlaceAction.onNavigationAction();
              },
            ),
            CupertinoDialogAction(
              child: Text('Send Email'),
              onPressed: () async {
                await PlaceAction.onSendEmailAction();
              },
            )
          ],
        ),
      );
    }
  }

  Future<void> _mapUpdate() async {
    var markers = <Marker>{};
    var places = await AppStorage.getFromStorage();
    for (var place in places) {
      markers.add(await _createPlaceMarker(context, place));
    }
    setState(() {
      _markers.addAll(markers);
    });

    // Zoom to fit the initially selected category.
    var pls = _markedPlaces.values.toList();
    await _zoomToFitPlaces(pls);
  }

  Future<void> _restoreFromDrive() async {
    var gDriveMng = GoogleDriveManager();
    await gDriveMng.loginWithGoogle();
    if (signedIn && googleSignInAccount != null) {
      GoogleDriveManager.listGoogleDriveFiles().then((value) async {
        var items = json.decode(String.fromCharCodes(value)) as List;
        var places = items
            .cast<Map<String, dynamic>>()
            .map((item) => Place.fromJson(item))
            .toList();
        AppStorage.setPlaces(places);
        await AppStorage.saveToStorage();
        _mapUpdate();
      });
    }
  }

  Future<void> _firstRun() async {
    if (await AppStorage.isFirstRun()) {
      AppStorage.unsetFirstRun();
      notificationInitialize(context);
      await showDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text('Confirm'),
          content: Text(
              'You started the app for the first time.\n Would you like to restore the harvest data from Google Drive?'),
          actions: [
            CupertinoDialogAction(
              child: Text('Yes'),
              onPressed: () => Navigator.pop(context, false),
            ),
            CupertinoDialogAction(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context, true),
            )
          ],
        ),
      ).then((exit) async {
        if (exit == null) return;
        if (!exit) {
          _restoreFromDrive();
        }
      });
    }
  }

  Future<Marker> _createPlaceMarker(BuildContext context, Place place) async {
    final marker = Marker(
        markerId: MarkerId(place.address + place.id),
        position: LatLng(place.latitude, place.longitude),
        infoWindow: InfoWindow(
          title: place.address,
          snippet: '',
          onTap: () => _pushPlaceDetailsScreen(place),
        ),
        onTap: () => _handleMarkerTap(place),
        icon: await _getPlaceMarkerIcon(context, place, false),
        visible: true //place.category == AppState.of(context).selectedCategory,
        );
    _markedPlaces[marker] = place;
    return marker;
  }

  Future<void> _handleMarkerTap(Place place) async {
    /* var marker = _markedPlaces.keys.singleWhere((key) => place.id ==_markedPlaces[key].id);
    var _marker = _markers.singleWhere((element) => element.markerId == marker.markerId);
    var isExist = true;
    var timer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (_selectedPlaces.isEmpty) {
        timer.cancel();
        if (!isExist) {
          setState(() {
            _markers.add(_marker);
          });
        }
        return;
      }
      setState(() {
        _pendingMarker = null;
        if (isExist) {
          _markers.remove(_marker);
        } else {
          _markers.add(_marker);
        }
        isExist = !isExist;
      });
    });
    _markerTimers.add(timer); */
    _updateExistingPlaceMarker(place: place);
    setState(() {
      _selectedPlaces.add(place);
    });
  }

  Future<void> _pushPlaceDetailsScreen(Place place) async {
    assert(place != null);
    var now = DateTime.now();
    place.lastDate = place.lastDate.isNotEmpty
        ? place.lastDate
        : DateFormat('dd/MM/yyyy').format(now);
    place.readyDate = place.readyDate.isNotEmpty
        ? place.readyDate
        : DateFormat('dd/MM/yyyy')
            .format(DateTime(now.year, now.month + 3, now.day));
    place.countTrees = place.countTrees != 0 ? place.countTrees : 1;

    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (context) {
        return PlaceDetails(
            place: place,
            navPlaces: [],
            onChanged: (value) => _onPlaceChanged(value),
            onRemoved: (value) => _onPlaceRemoved(value));
      }),
    );
  }

  Future<void> _onPlaceChanged(Place value) async {
    // Replace the place with the modified version.
    final newPlaces = List<Place>.from(await AppStorage.getFromStorage());
    final index = newPlaces.indexWhere((place) => place.id == value.id);
    setState(() {
      _selectedPlaces.removeWhere((item) => item.id == value.id);
      _selectedPlaces.add(value);
    });

    newPlaces[index] = value;

    _updateExistingPlaceMarker(place: value);
    _configuration = MapConfiguration(
      selectedCategory: AppState.of(context).selectedCategory,
    );
    AppStorage.setPlaces(newPlaces);
    AppStorage.saveToStorage();
    _onUploadDrivePressed();
  }

  Future<void> _onPlaceRemoved(Place place) async {
    final newPlaces = List<Place>.from(await AppStorage.getFromStorage());
    final index = newPlaces.indexWhere((pl) => pl.id == place.id);
    newPlaces.removeAt(index);

    setState(() {
      var marker = _markedPlaces.keys
          .singleWhere((value) => _markedPlaces[value].id == place.id);
      _markers.remove(marker);
      _markedPlaces.remove(marker);
      _selectedPlaces.removeWhere((item) => item.id == place.id);
    });
    // Manually update our map configuration here since our map is already
    // updated with the new marker. Otherwise, the map would be reconfigured
    // in the main build method due to a modified AppState.
    _configuration = MapConfiguration(
      /* places: newPlaces, */
      selectedCategory: AppState.of(context).selectedCategory,
    );
    AppStorage.setPlaces(newPlaces);
    AppStorage.saveToStorage();
    _onUploadDrivePressed();
  }

  Future<void> _updateExistingPlaceMarker({@required Place place}) async {
    var marker = _markedPlaces.keys
        .singleWhere((value) => _markedPlaces[value].id == place.id);
    var placeMarker = await _getPlaceMarkerIcon(context, place, true);
    setState(() {
      final updatedMarker = marker.copyWith(
          infoWindowParam: InfoWindow(
            title: place.address,
            snippet: place.starRating != 0 ? '' : null,
            onTap: () => _pushPlaceDetailsScreen(place),
          ),
          iconParam: placeMarker,
          positionParam: LatLng(place.latitude, place.longitude),
          onTapParam: () => _handleMarkerTap(place),
          visibleParam:
              true //place.category == AppState.of(context).selectedCategory,
          );
      _updateMarker(marker: marker, updatedMarker: updatedMarker, place: place);
    });
  }

  void _updateMarker({
    @required Marker marker,
    @required Marker updatedMarker,
    @required Place place,
  }) {
    _markers.remove(marker);
    _markedPlaces.remove(marker);

    _markers.add(updatedMarker);
    _markedPlaces[updatedMarker] = place;
  }

  Future<void> _switchSelectedCategory(PlaceCategory category) async {
    AppState.updateWith(context, selectedCategory: category);
    await _showPlacesForSelectedCategory(category);
  }

  Future<void> _showPlacesForSelectedCategory(PlaceCategory category) async {
    setState(() {
      for (var marker in List.of(_markedPlaces.keys)) {
        final place = _markedPlaces[marker];
        final updatedMarker =
            marker.copyWith(visibleParam: true); //place.category == category,

        _updateMarker(
          marker: marker,
          updatedMarker: updatedMarker,
          place: place,
        );
      }
    });

    await _zoomToFitPlaces(_markedPlaces.values.toList());
    //_getPlacesForCategory(category, _markedPlaces.values.toList(),)
  }

  Future<void> _zoomToFitPlaces(List<Place> places) async {
    var controller = await mapController.future;

    // Default min/max values to latitude and longitude of center.
    var minLat = widget.center.latitude;
    var maxLat = widget.center.latitude;
    var minLong = widget.center.longitude;
    var maxLong = widget.center.longitude;

    for (var place in places) {
      minLat = min(minLat, place.latitude);
      maxLat = max(maxLat, place.latitude);
      minLong = min(minLong, place.longitude);
      maxLong = max(maxLong, place.longitude);
    }

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLong),
          northeast: LatLng(maxLat, maxLong),
        ),
        48.0,
      ),
    );
  }

  Future<void> _onAddPlacePressed() async {
    setState(() {
      final newMarker = Marker(
        markerId: MarkerId(_lastMapPosition.toString() + '- new'),
        position: _lastMapPosition,
        infoWindow: InfoWindow(title: 'New Place'),
        draggable: true,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );
      _markers.add(newMarker);
      _pendingMarker = newMarker;
    });
  }

  Future<void> _onLongPressMap(LatLng point) async {
    _lastMapPosition = point;
    await _onAddPlacePressed();
  }

  Future<void> _markerClear(LatLng point) async {
    var markers = <Marker>{};
    _markedPlaces.clear();
    var places = await AppStorage.getFromStorage();
    for (var place in places) {
      markers.add(await _createPlaceMarker(context, place));
    }
    setState(() {
      _markers.clear();
      _markers.addAll(markers);
      _selectedPlaces.clear();

      /* _markerTimers.map((e) => e.cancel());
      _markerTimers.clear(); */
      _pendingMarker = null;
    });
  }

  Future<void> _confirmAddPlace(BuildContext context) async {
    if (_pendingMarker != null) {
      // Create a new Place and map it to the marker we just added.
      final newPlace = Place(
        Uuid().v1(),
        _pendingMarker.position.latitude,
        _pendingMarker.position.longitude,
        _pendingMarker.infoWindow.title,
        AppState.of(context).selectedCategory,
        '',
        '',
        0,
        '',
        0,
      );

      var placeMarker = await _getPlaceMarkerIcon(context, newPlace, false);

      setState(() {
        final updatedMarker = _pendingMarker.copyWith(
          iconParam: placeMarker,
          infoWindowParam: InfoWindow(
            title: 'New Place',
            snippet: null,
            onTap: () => _pushPlaceDetailsScreen(newPlace),
          ),
          draggableParam: false,
        );

        _updateMarker(
          marker: _pendingMarker,
          updatedMarker: updatedMarker,
          place: newPlace,
        );

        _pendingMarker = null;
      });

      // Show a confirmation snackbar that has an action to edit the new place.
      Scaffold.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 3),
          content:
              const Text('New place added.', style: TextStyle(fontSize: 16.0)),
          action: SnackBarAction(
            label: 'Edit',
            onPressed: () async {
              await _pushPlaceDetailsScreen(newPlace);
            },
          ),
        ),
      );

      // Add the new place to the places stored in appState.
      final newPlaces = List<Place>.from(await AppStorage.getFromStorage())
        ..add(newPlace);

      _configuration = MapConfiguration(
        /* places: newPlaces, */
        selectedCategory: AppState.of(context).selectedCategory,
      );

      //AppState.updateWith(context, places: newPlaces);
      AppStorage.setPlaces(newPlaces);
      AppStorage.saveToStorage();
      _onUploadDrivePressed();
    }
  }

  void _cancelAddPlace() {
    if (_pendingMarker != null) {
      setState(() {
        _markers.remove(_pendingMarker);
        _pendingMarker = null;
      });
    }
  }

  void _onToggleMapTypePressed() {
    final nextType =
        MapType.values[(_currentMapType.index + 1) % MapType.values.length];

    setState(() {
      _currentMapType = nextType;
    });
  }

  Future<void> _onUploadDrivePressed() async {
    var plList = await AppStorage.getFromStorage();
    var gDriveMng = GoogleDriveManager();
    await gDriveMng.loginWithGoogle();
    if (signedIn && googleSignInAccount != null)
      gDriveMng.uploadFileToGoogleDrive(jsonEncode(plList));
  }

  Future<void> _onSendEmail() async {
    await PlaceAction.onSendEmail(_selectedPlaces.toList());
  }

  Future<void> _onNavigate() async {
    await PlaceAction.onNavigate(_selectedPlaces.toList());
  }

  @override
  Widget build(BuildContext context) {
    //_maybeUpdateMapConfiguration();

    return Builder(builder: (context) {
      // We need this additional builder here so that we can pass its context to
      // _AddPlaceButtonBar's onSavePressed callback. This callback shows a
      // SnackBar and to do this, we need a build context that has Scaffold as
      // an ancestor.
      return Center(
        child: Stack(
          children: <Widget>[
            GoogleMap(
              onMapCreated: onMapCreated,
              initialCameraPosition: CameraPosition(
                target: widget.center,
                zoom: 11.0,
              ),
              onTap: _markerClear,
              onLongPress: _onLongPressMap,
              mapType: _currentMapType,
              markers: _markers,
              onCameraMove: (position) => _lastMapPosition = position.target,
            ),
            /* _CategoryButtonBar(
              selectedPlaceCategory: AppState.of(context).selectedCategory,
              visible: _selectedPlaces.isEmpty && _pendingMarker == null,
              onChanged: _switchSelectedCategory,
            ), */
            _AddPlaceButtonBar(
              visible: _selectedPlaces.isEmpty && _pendingMarker != null,
              onSavePressed: () => _confirmAddPlace(context),
              onCancelPressed: _cancelAddPlace,
            ),
            _MapFabs(
                visible: _selectedPlaces.isEmpty && _pendingMarker == null,
                onAddPlacePressed: _onAddPlacePressed,
                onToggleMapTypePressed: _onToggleMapTypePressed,
                onUploadDrivePressed: _onUploadDrivePressed),
            _SelectedMarkers(
              count: _selectedPlaces.length,
              visible: _selectedPlaces.isNotEmpty,
              onSendEmail: _onSendEmail,
              onNavigate: _onNavigate,
            ),
          ],
        ),
      );
    });
  }
}

class _CategoryButtonBar extends StatelessWidget {
  const _CategoryButtonBar({
    Key key,
    @required this.selectedPlaceCategory,
    @required this.visible,
    @required this.onChanged,
  })  : assert(selectedPlaceCategory != null),
        assert(visible != null),
        assert(onChanged != null),
        super(key: key);

  final PlaceCategory selectedPlaceCategory;
  final bool visible;
  final ValueChanged<PlaceCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible,
      child: Container(
        padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 14.0),
        alignment: Alignment.bottomCenter,
        child: ButtonBar(
          alignment: MainAxisAlignment.center,
          children: <Widget>[
            RaisedButton(
              color: selectedPlaceCategory == PlaceCategory.favorite
                  ? Colors.green[700]
                  : Colors.lightGreen,
              child: const Text(
                'Favorites',
                style: TextStyle(color: Colors.white, fontSize: 14.0),
              ),
              onPressed: () => onChanged(PlaceCategory.favorite),
            ),
            RaisedButton(
              color: selectedPlaceCategory == PlaceCategory.visited
                  ? Colors.green[700]
                  : Colors.lightGreen,
              child: const Text(
                'Visited',
                style: TextStyle(color: Colors.white, fontSize: 14.0),
              ),
              onPressed: () => onChanged(PlaceCategory.visited),
            ),
            RaisedButton(
              color: selectedPlaceCategory == PlaceCategory.wantToGo
                  ? Colors.green[700]
                  : Colors.lightGreen,
              child: const Text(
                'Want To Go',
                style: TextStyle(color: Colors.white, fontSize: 14.0),
              ),
              onPressed: () => onChanged(PlaceCategory.wantToGo),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPlaceButtonBar extends StatelessWidget {
  const _AddPlaceButtonBar({
    Key key,
    @required this.visible,
    @required this.onSavePressed,
    @required this.onCancelPressed,
  })  : assert(visible != null),
        assert(onSavePressed != null),
        assert(onCancelPressed != null),
        super(key: key);

  final bool visible;
  final VoidCallback onSavePressed;
  final VoidCallback onCancelPressed;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible,
      child: Container(
        padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 14.0),
        alignment: Alignment.bottomCenter,
        child: ButtonBar(
          alignment: MainAxisAlignment.center,
          children: <Widget>[
            RaisedButton(
              color: Colors.blue,
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white, fontSize: 16.0),
              ),
              onPressed: onSavePressed,
            ),
            RaisedButton(
              color: Colors.red,
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white, fontSize: 16.0),
              ),
              onPressed: onCancelPressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedMarkers extends StatelessWidget {
  const _SelectedMarkers({
    Key key,
    @required this.count,
    @required this.visible,
    @required this.onSendEmail,
    @required this.onNavigate,
  })  : assert(count != null),
        assert(visible != null),
        assert(onSendEmail != null),
        assert(onNavigate != null),
        super(key: key);

  final int count;
  final bool visible;
  final VoidCallback onSendEmail;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.bottomCenter,
      child: Visibility(
          visible: visible,
          child: Container(
            color: Colors.grey[300],
            child: Row(
              children: <Widget>[
                SizedBox(width: 20.0),
                Text('Selected: $count'),
                SizedBox(width: 20.0),
                RaisedButton(
                  color: Colors.cyan,
                  textColor: Colors.white,
                  onPressed: onSendEmail,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.mail),
                      Text('Send Email'),
                    ],
                  ),
                ),
                SizedBox(width: 20.0),
                RaisedButton(
                  color: Colors.cyan,
                  textColor: Colors.white,
                  onPressed: onNavigate,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.navigation),
                      Text('Navigate'),
                    ],
                  ),
                ),
              ],
            ),
          )),
    );
  }
}

class _MapFabs extends StatelessWidget {
  const _MapFabs({
    Key key,
    @required this.visible,
    @required this.onAddPlacePressed,
    @required this.onToggleMapTypePressed,
    @required this.onUploadDrivePressed,
  })  : assert(visible != null),
        assert(onAddPlacePressed != null),
        assert(onToggleMapTypePressed != null),
        assert(onUploadDrivePressed != null),
        super(key: key);

  final bool visible;
  final VoidCallback onAddPlacePressed;
  final VoidCallback onToggleMapTypePressed;
  final VoidCallback onUploadDrivePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topRight,
      margin: const EdgeInsets.only(top: 12.0, right: 12.0),
      child: Visibility(
        visible: visible,
        child: Column(
          children: <Widget>[
            FloatingActionButton(
              heroTag: 'add_place_button',
              onPressed: onAddPlacePressed,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              backgroundColor: Colors.green,
              child: const Icon(Icons.add_location, size: 36.0),
            ),
            SizedBox(height: 12.0),
            FloatingActionButton(
              heroTag: 'toggle_map_type_button',
              onPressed: onToggleMapTypePressed,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              mini: true,
              backgroundColor: Colors.green,
              child: const Icon(Icons.layers, size: 28.0),
            ),
            SizedBox(height: 12.0),
            FloatingActionButton(
              heroTag: 'drive_upload_button',
              onPressed: onUploadDrivePressed,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              mini: true,
              backgroundColor: Colors.green,
              child: const Icon(Icons.cloud_upload, size: 28.0),
            ),
          ],
        ),
      ),
    );
  }
}

class MapConfiguration {
  MapConfiguration({
    /* @required this.places, */
    @required this.selectedCategory,
  }) : /* assert(places != null), */
        assert(selectedCategory != null);

  /* final List<Place> places; */
  final PlaceCategory selectedCategory;
  List<Place> places;

  @override
  int get hashCode => /* places.hashCode ^ */ selectedCategory.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other.runtimeType != runtimeType) {
      return false;
    }

    return other is MapConfiguration &&
        /* other.places == places && */
        other.selectedCategory == selectedCategory;
  }

  static MapConfiguration of(AppState appState) {
    return MapConfiguration(
      /* places: AppStorage.getFromStorage(), */
      selectedCategory: appState.selectedCategory,
    );
  }
}
