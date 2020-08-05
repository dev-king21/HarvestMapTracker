import 'package:json_annotation/json_annotation.dart';

part 'place.g.dart';
enum PlaceCategory {
  favorite,
  visited,
  wantToGo,
}


@JsonSerializable()
class Place {
  
  Place(
    this.id,
    this.latitude,
    this.longitude,
    this.address,
    this.category,
    this.lastDate,
    this.readyDate,
    this.countTrees,
    this.description,
    this.starRating
  );  

  String id;
  String address;
  String lastDate;
  String readyDate;
  int countTrees; 
  PlaceCategory category;
  String description;
  int starRating;
  double latitude;
  double longitude;

  Place copyWith({
    String id,
    double latitude,
    double longitude,
    String address,
    PlaceCategory category,
    String description,
    String lastDate,
    String readyDate,
    int countTrees,
    int starRating,
  }) {
    return Place(
      id ?? this.id,
      latitude ?? this.latitude,
      longitude ?? this.longitude,
      address ?? this.address,
      category ?? this.category,
      lastDate ?? this.lastDate,
      readyDate ?? this.readyDate,
      countTrees ?? this.countTrees,
      description ?? this.description,
      starRating ?? this.starRating,
    );
  }

  factory Place.fromJson(Map<String, dynamic> json) => _$PlaceFromJson(json);
  Map<String, dynamic> toJson() => _$PlaceToJson(this);

}
