// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Place _$PlaceFromJson(Map<String, dynamic> json) {
  return Place(
    json['id'] as String,
    (json['latitude'] as num)?.toDouble(),
    (json['longitude'] as num)?.toDouble(),
    json['address'] as String,
    _$enumDecodeNullable(_$PlaceCategoryEnumMap, json['category']),
    json['lastDate'] as String,
    json['readyDate'] as String,
    json['countTrees'] as int,
    json['description'] as String,
    json['starRating'] as int,
  );
}

Map<String, dynamic> _$PlaceToJson(Place instance) => <String, dynamic>{
      'id': instance.id,
      'address': instance.address,
      'lastDate': instance.lastDate,
      'readyDate': instance.readyDate,
      'countTrees': instance.countTrees,
      'category': _$PlaceCategoryEnumMap[instance.category],
      'description': instance.description,
      'starRating': instance.starRating,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

T _$enumDecode<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }

  final value = enumValues.entries
      .singleWhere((e) => e.value == source, orElse: () => null)
      ?.key;

  if (value == null && unknownValue == null) {
    throw ArgumentError('`$source` is not one of the supported values: '
        '${enumValues.values.join(', ')}');
  }
  return value ?? unknownValue;
}

T _$enumDecodeNullable<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<T>(enumValues, source, unknownValue: unknownValue);
}

const _$PlaceCategoryEnumMap = {
  PlaceCategory.favorite: 'favorite',
  PlaceCategory.visited: 'visited',
  PlaceCategory.wantToGo: 'wantToGo',
};
