import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import 'app_model.dart';
import 'app_storage.dart';
import 'place.dart';
import 'place_list.dart';
import 'place_map.dart';

enum PlaceTrackerViewType {
  map,
  list,
}

class HarvestTrackerApp extends StatefulWidget {
  @override
  _HarvestTrackerAppState createState() => _HarvestTrackerAppState();
}

class _HarvestTrackerAppState extends State<HarvestTrackerApp> {
  /* AppState appState = AppState(); */
  LatLng center;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        return AppModel<AppState>(
          initialState: AppState(),
          child: child,
        );
      },
      home: _PlaceTrackerHomePage(),
    );
  }
}

Future<LatLng> getCurrentLocation() async {
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
  var curPos = LatLng(position.latitude, position.longitude);
  AppStorage.setLatLng(curPos);

  return curPos;
}

class _PlaceTrackerHomePage extends StatelessWidget {
  const _PlaceTrackerHomePage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LatLng>(
        future: getCurrentLocation(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const <Widget>[
                    Padding(
                      padding: EdgeInsets.fromLTRB(0.0, 0.0, 8.0, 0.0),
                      child: Icon(Icons.pin_drop, size: 24.0),
                    ),
                    Text('Coconut Harvest Tracker'),
                  ],
                ),
                backgroundColor: Colors.green[700],
                actions: <Widget>[
                  Padding(
                    padding: EdgeInsets.fromLTRB(0.0, 0.0, 16.0, 0.0),
                    child: IconButton(
                      icon: Icon(
                        AppState.of(context).viewType ==
                                PlaceTrackerViewType.map
                            ? Icons.list
                            : Icons.map,
                        size: 32.0,
                      ),
                      onPressed: () {
                        AppState.updateWith(
                          context,
                          viewType: AppState.of(context).viewType ==
                                  PlaceTrackerViewType.map
                              ? PlaceTrackerViewType.list
                              : PlaceTrackerViewType.map,
                        );
                      },
                    ),
                  ),
                ],
              ),
              body: IndexedStack(
                index: AppState.of(context).viewType == PlaceTrackerViewType.map
                    ? 0
                    : 1,
                children: <Widget>[
                  PlaceMap(center: snapshot.data),
                  PlaceList(),
                ],
              ),
            );
          } else {
            return Scaffold(
                appBar: AppBar(
                    title: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: const <Widget>[
                        Padding(
                          padding: EdgeInsets.fromLTRB(0.0, 0.0, 8.0, 0.0),
                          child: Icon(Icons.pin_drop, size: 24.0),
                        ),
                        Text('Coconut Harvest Tracker'),
                      ],
                    ),
                    backgroundColor: Colors.green[700]),
                body: Center(child: CircularProgressIndicator()));
          }
        });
  }
}

class AppState {
  const AppState({
    /* this.places = StubData.places, */ // AppStorage.getFromStorage(),
    this.selectedCategory = PlaceCategory.favorite,
    this.viewType = PlaceTrackerViewType.map,
  }) : /* assert(places != null), */
        assert(selectedCategory != null);

  /* final List<Place> places; */
  final PlaceCategory selectedCategory;
  final PlaceTrackerViewType viewType;

  AppState copyWith({
    List<Place> places,
    PlaceCategory selectedCategory,
    PlaceTrackerViewType viewType,
  }) {
    return AppState(
      /* places: places ?? this.places, */
      selectedCategory: selectedCategory ?? this.selectedCategory,
      viewType: viewType ?? this.viewType,
    );
  }

  /* static AppState of(BuildContext context) => AppModel.of<AppState>(context); */
  static AppState of(BuildContext context) {
    return AppModel.of<AppState>(context);
  }

  static void update(BuildContext context, AppState newState) {
    AppModel.update<AppState>(context, newState);
  }

  static void updateWith(
    BuildContext context, {
    /* List<Place> places, */
    PlaceCategory selectedCategory,
    PlaceTrackerViewType viewType,
  }) {
    update(
      context,
      AppState.of(context).copyWith(
        /* places: places, */
        selectedCategory: selectedCategory,
        viewType: viewType,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is AppState &&
        /* other.places == places && */
        other.selectedCategory == selectedCategory &&
        other.viewType == viewType;
  }

  @override
  int get hashCode => hashValues(/* places,  */ selectedCategory, viewType);
}
