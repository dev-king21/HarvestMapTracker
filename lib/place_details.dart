import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import 'place.dart';
//import 'stub_data.dart';

class PlaceDetails extends StatefulWidget {
  PlaceDetails({
    @required this.place,
    @required this.navPlaces,
    @required this.onChanged,
    @required this.onRemoved,
    Key key,
  })  : assert(place != null),
        assert(onChanged != null),
        super(key: key);

  final Place place;
  final List<Place> navPlaces; 
  /* final ValueChanged<Place> onChanged; */
  final void Function(Place) onChanged;
  final void Function(Place) onRemoved;
  int curNav = 0;

  @override
  PlaceDetailsState createState() => PlaceDetailsState();
}

class PlaceDetailsState extends State<PlaceDetails> {
  Place _place;
  GoogleMapController _mapController;
  final Set<Marker> _markers = {};

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _lastDateController = TextEditingController();
  final TextEditingController _readyDateController = TextEditingController();
  final TextEditingController _countTreesController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    _place = widget.place;
    _addressController.text = _place.address;
    _lastDateController.text = _place.lastDate;
    _readyDateController.text = _place.readyDate;
    _countTreesController.text = _place.countTrees.toString();
    _descriptionController.text = _place.description;
    return super.initState();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() {
      _markers.add(Marker(
        markerId: MarkerId(_place.address),
        position: LatLng(_place.latitude, _place.longitude),
      ));
    });
  }

  Widget _detailsBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 12.0),
      children: <Widget>[
        Visibility(
          visible: widget.navPlaces.length > 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RaisedButton(
                  color: Colors.red,
                  textColor: Colors.white,
                  onPressed: () {
                    setState((){
                      var prevNav = 0;
                      if (widget.curNav == 0) {
                        prevNav = widget.navPlaces.length - 1;
                      }
                      _place = widget.navPlaces[prevNav];
                      _addressController.text = _place.address;
                      _lastDateController.text = _place.lastDate;
                      _readyDateController.text = _place.readyDate;
                      _countTreesController.text = _place.countTrees.toString();
                      _descriptionController.text = _place.description;
                      widget.curNav = prevNav;
                    });
                  },
                  child: Text('Prev'),
                ),
                RaisedButton(
                  color: Colors.green[500],
                  textColor: Colors.white,
                  onPressed: (){
                    setState((){
                      var nextNav = widget.curNav + 1;
                      if (widget.curNav == widget.navPlaces.length - 1) {
                        nextNav = 0;
                      }
                      _place = widget.navPlaces[nextNav];
                      _addressController.text = _place.address;
                      _lastDateController.text = _place.lastDate;
                      _readyDateController.text = _place.readyDate;
                      _countTreesController.text = _place.countTrees.toString();
                      _descriptionController.text = _place.description;
                      widget.curNav = nextNav;
                    });
                  },
                  child: Text('Next'),
                )
              ]
            ),
          )
        ),
        _AddressTextField(
          controller: _addressController,
          onChanged: (value) {
            setState(() {
              _place = _place.copyWith(address: value);
            });
          },
        ),
        _LastDateTextField(
          controller: _lastDateController,
          onChanged: (value) {
            setState(() {
              _place = _place.copyWith(lastDate: value);
            });
          },
        ),
        _ReadyDateTextField(
          controller: _readyDateController,
          onChanged: (value) {
            setState(() {
              _place = _place.copyWith(readyDate: value);
            });
          },
        ),
        _CountTreesTextField(
          controller: _countTreesController,
          onChanged: (value) {
            setState(() {
              _place = _place.copyWith(countTrees: int.parse(value));
            });
          },
        ),
        _DescriptionTextField(
          controller: _descriptionController,
          onChanged: (value) {
            setState(() {
              _place = _place.copyWith(description: value);
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RaisedButton(
                color: Colors.red,
                textColor: Colors.white,
                onPressed: (){
                  widget.onRemoved(_place);
                  Navigator.pop(context);
                }, 
                child: Text('REMOVE'),
              ),
              RaisedButton(
                color: Colors.green[500],
                textColor: Colors.white,
                onPressed: () {
                  var now = DateTime.now();
                  var lastDateStr = DateFormat('dd/MM/yyyy').format(now);
                  var readyDateStr = DateFormat('dd/MM/yyyy').format(DateTime(now.year, now.month + 3, now.day));

                  _place.lastDate = lastDateStr;
                  _place.readyDate = readyDateStr;
                  widget.onChanged(_place);
                  Navigator.pop(context);
                },
                child: Text('HARVEST'),
              ),
            ]
          ),
        ),
        _Map(
          center: LatLng(_place.latitude, _place.longitude),
          mapController: _mapController,
          onMapCreated: _onMapCreated,
          markers: _markers,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_place.address}'),
        backgroundColor: Colors.green[700],
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(0.0, 0.0, 8.0, 0.0),
            child: IconButton(
              icon: const Icon(Icons.save, size: 30.0),
              onPressed: () {
                widget.onChanged(_place);
                Navigator.pop(context);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0.0, 0.0, 8.0, 0.0),
            child: IconButton(
              icon: const Icon(Icons.crop, size: 30.0),
              onPressed: () {
                widget.onChanged(_place);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: _detailsBody(),
      ),
    );
  }
}

class _AddressTextField extends StatelessWidget {
  const _AddressTextField({
    @required this.controller,
    @required this.onChanged,
    Key key,
  })  : assert(controller != null),
        assert(onChanged != null),
        super(key: key);

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 16.0),
      child: TextField(
        decoration: const InputDecoration(
          labelText: 'Address',
          labelStyle: TextStyle(fontSize: 18.0),
        ),
        style: const TextStyle(fontSize: 20.0, color: Colors.black87),
        autocorrect: true,
        controller: controller,
        onChanged: (value) {
          onChanged(value);
        },
      ),
    );
  }
}

class _LastDateTextField extends StatelessWidget {
  const _LastDateTextField({
    @required this.controller,
    @required this.onChanged,
    Key key,
  })  : assert(controller != null),
        assert(onChanged != null),
        super(key: key);

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 16.0),
      child: TextField(
        decoration: const InputDecoration(
          labelText: 'Last Harvest Date',
          labelStyle: TextStyle(fontSize: 18.0),
        ),
        style: const TextStyle(fontSize: 20.0, color: Colors.black87),
        autocorrect: true,
        controller: controller,
        onChanged: (value) {
          onChanged(value);
        },
      ),
    );
  }
}

class _ReadyDateTextField extends StatelessWidget {
  const _ReadyDateTextField({
    @required this.controller,
    @required this.onChanged,
    Key key,
  })  : assert(controller != null),
        assert(onChanged != null),
        super(key: key);

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 16.0),
      child: TextField(
        decoration: const InputDecoration(
          labelText: 'Ready For Harvest Date',
          labelStyle: TextStyle(fontSize: 18.0),
        ),
        style: const TextStyle(fontSize: 20.0, color: Colors.black87),
        autocorrect: true,
        controller: controller,
        onChanged: (value) {
          onChanged(value);
        },
      ),
    );
  }
}

class _CountTreesTextField extends StatelessWidget {
  const _CountTreesTextField({
    @required this.controller,
    @required this.onChanged,
    Key key,
  })  : assert(controller != null),
        assert(onChanged != null),
        super(key: key);

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 16.0),
      child: TextField(
        decoration: const InputDecoration(
          labelText: 'Number of Trees',
          labelStyle: TextStyle(fontSize: 18.0),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
            WhitelistingTextInputFormatter.digitsOnly
        ],
        style: const TextStyle(fontSize: 20.0, color: Colors.black87),
        autocorrect: true,
        controller: controller,
        onChanged: (value) {
          onChanged(value);
        },
      ),
    );
  }
}

/* class _NameTextField extends StatelessWidget {
  const _NameTextField({
    @required this.controller,
    @required this.onChanged,
    Key key,
  })  : assert(controller != null),
        assert(onChanged != null),
        super(key: key);

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 16.0),
      child: TextField(
        decoration: const InputDecoration(
          labelText: 'Name',
          labelStyle: TextStyle(fontSize: 18.0),
        ),
        style: const TextStyle(fontSize: 20.0, color: Colors.black87),
        autocorrect: true,
        controller: controller,
        onChanged: (value) {
          onChanged(value);
        },
      ),
    );
  }
} */

class _DescriptionTextField extends StatelessWidget {
  const _DescriptionTextField({
    @required this.controller,
    @required this.onChanged,
    Key key,
  })  : assert(controller != null),
        assert(onChanged != null),
        super(key: key);

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 16.0),
      child: TextField(
        decoration: const InputDecoration(
          labelText: 'Description',
          labelStyle: TextStyle(fontSize: 18.0),
        ),
        style: const TextStyle(fontSize: 20.0, color: Colors.black87),
        maxLines: null,
        autocorrect: true,
        controller: controller,
        onChanged: (value) {
          onChanged(value);
        },
      ),
    );
  }
}

/* 
class _StarBar extends StatelessWidget {
  const _StarBar({
    @required this.rating,
    @required this.onChanged,
    Key key,
  })  : assert(rating != null && rating >= 0 && rating <= maxStars),
        assert(onChanged != null),
        super(key: key);

  static const int maxStars = 5;
  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxStars, (index) {
        return IconButton(
          icon: const Icon(Icons.star),
          iconSize: 40.0,
          color: rating > index ? Colors.amber : Colors.grey[400],
          onPressed: () {
            onChanged(index + 1);
          },
        );
      }).toList(),
    );
  }
}
 */
class _Map extends StatelessWidget {
  const _Map({
    @required this.center,
    @required this.mapController,
    @required this.onMapCreated,
    @required this.markers,
    Key key,
  })  : assert(center != null),
        assert(onMapCreated != null),
        super(key: key);

  final LatLng center;
  final GoogleMapController mapController;
  final ArgumentCallback<GoogleMapController> onMapCreated;
  final Set<Marker> markers;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      elevation: 4.0,
      child: SizedBox(
        width: 340.0,
        height: 240.0,
        child: GoogleMap(
          onMapCreated: onMapCreated,
          initialCameraPosition: CameraPosition(
            target: center,
            zoom: 16.0,
          ),
          markers: markers,
          zoomGesturesEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          scrollGesturesEnabled: false,
        ),
      ),
    );
  }
}

/* 
class _Reviews extends StatelessWidget {
  const _Reviews({
    Key key,
  }) : super(key: key);

  Widget _buildSingleReview(String reviewText) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            children: <Widget>[
              Container(
                width: 80.0,
                height: 80.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40.0),
                  border: Border.all(
                    width: 3.0,
                    color: Colors.grey,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const <Widget>[
                    Text(
                      '5',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 36.0,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Text(
                  reviewText,
                  style: const TextStyle(fontSize: 20.0, color: Colors.black87),
                  maxLines: null,
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 8.0,
          color: Colors.grey[700],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 8.0),
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              'Reviews',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        Column(
          children: StubData.reviewStrings
              .map((reviewText) => _buildSingleReview(reviewText))
              .toList(),
        ),
      ],
    );
  }
}

 */