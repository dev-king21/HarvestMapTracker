import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum PlaceCategory {
  favorite,
  visited,
  wantToGo,
}

class Place {
  const Place({
    @required this.id,
    @required this.latLng,
    @required this.address,
    @required this.category,
    this.lastDate,
    this.readyDate,
    @required this.countTrees,
    this.description,
    this.starRating = 0,
  })  : assert(id != null),
        assert(latLng != null),
        assert(address != null),
        assert(category != null),
        assert(starRating != null && starRating >= 0 && starRating <= 5);

  final String id;
  final LatLng latLng;
  final String address;
  final String lastDate;
  final String readyDate;
  final int countTrees; 
  final PlaceCategory category;
  final String description;
  final int starRating;


  double get latitude => latLng.latitude;
  double get longitude => latLng.longitude;

  Place copyWith({
    String id,
    LatLng latLng,
    String address,
    PlaceCategory category,
    String description,
    String lastDate,
    String readyDate,
    int countTrees,
    int starRating,
  }) {
    return Place(
      id: id ?? this.id,
      latLng: latLng ?? this.latLng,
      address: address ?? this.address,
      category: category ?? this.category,
      lastDate: lastDate ?? this.lastDate,
      readyDate: lastDate ?? this.readyDate,
      countTrees: countTrees ?? this.countTrees,
      description: description ?? this.description,
      starRating: starRating ?? this.starRating,
    );
  }
}
