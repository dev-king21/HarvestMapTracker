import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'place.dart';

class StubData {
  static const List<Place> places = [
    Place(
      id: '1',
      latLng: LatLng(45.524676, -122.681922),
      address: 'Deschutes Brewery',
      lastDate: '04/20/2020',
      readyDate: '07/20/2020',
      countTrees: 3,
      description:
          'Beers brewed on-site & gourmet pub grub in a converted auto-body shop with a fireplace & wood beams.',
      category: PlaceCategory.favorite,
      starRating: 5,
    ),
    Place(
      id: '2',
      latLng: LatLng(45.516887, -122.675417),
      address: 'Luc Lac Vietnamese Kitchen',
      lastDate: '04/20/2020',
      readyDate: '07/20/2020',
      countTrees: 1,
      description:
          'Popular counter-serve offering pho, banh mi & other Vietnamese favorites in a stylish setting.',
      category: PlaceCategory.favorite,
      starRating: 5,
    ),
    Place(
      id: '3',
      latLng: LatLng(45.528952, -122.698344),
      address: 'Salt & Straw',
      lastDate: '04/20/2020',
      readyDate: '07/20/2020',
      countTrees: 1,
      description:
          'Quirky flavors & handmade waffle cones draw crowds to this artisinal ice cream maker\'s 3 parlors.',
      category: PlaceCategory.favorite,
      starRating: 5,
    ),
    Place(
      id: '4',
      latLng: LatLng(45.525253, -122.684423),
      address: 'TILT',
      lastDate: '04/20/2020',
      readyDate: '07/20/2020',
      countTrees: 1,
      description:
          'This stylish American eatery offers unfussy breakfast fare, cocktails & burgers in industrial-themed digs.',
      category: PlaceCategory.favorite,
      starRating: 4,
    ),
    Place(
      id: '5',
      latLng: LatLng(45.513485, -122.657982),
      address: 'White Owl Social Club',
      lastDate: '04/20/2020',
      readyDate: '07/20/2020',
      countTrees: 1,
      description:
          'Chill haunt with local beers, burgers & vegan eats, plus live music & an airy patio with a fire pit.',
      category: PlaceCategory.favorite,
      starRating: 4,
    ),
    Place(
      id: '6',
      latLng: LatLng(45.487137, -122.799940),
      address: 'Buffalo Wild Wings',
      lastDate: '04/20/2020',
      readyDate: '07/20/2020',
      countTrees: 1,
      description:
          'Lively sports-bar chain dishing up wings & other American pub grub amid lots of large-screen TVs.',
      category: PlaceCategory.visited,
      starRating: 5,
    ),
    Place(
      id: '7',
      latLng: LatLng(45.416986, -122.743171),
      address: 'Chevys',
      lastDate: '04/20/2020',
      readyDate: '07/20/2020',
      countTrees: 1,
      description:
          'Lively, informal Mexican chain with a colorful, family-friendly setting plus tequilas & margaritas.',
      category: PlaceCategory.visited,
      starRating: 4,
    ),
    Place(
      id: '8',
      latLng: LatLng(45.430489, -122.831802),
      address: 'Cinetopia',
      lastDate: '04/20/2020',
      readyDate: '07/20/2020',
      countTrees: 1,
      description:
          'Moviegoers can take food from the on-site eatery to their seats, with table service in 21+ theaters.',
      category: PlaceCategory.visited,
      starRating: 4,
    ),
    Place(
      id: '9',
      latLng: LatLng(45.383030, -122.758372),
      address: 'Thai Cuisine',
      lastDate: '04/20/2020',
      readyDate: '07/20/2020',
      countTrees: 1,
      description:
          'Informal restaurant offering Thai standards in a modest setting, plus takeout & delivery.',
      category: PlaceCategory.visited,
      starRating: 4,
    ),
    Place(
      id: '10',
      latLng: LatLng(45.493321, -122.669330),
      address: 'The Old Spaghetti Factory',
      lastDate: '04/20/2020',
      readyDate: '07/20/2020',
      countTrees: 1,
      description:
          'Family-friendly chain eatery featuring traditional Italian entrees amid turn-of-the-century decor.',
      category: PlaceCategory.visited,
      starRating: 4,
    ),
    Place(
      id: '11',
      latLng: LatLng(45.548606, -122.675286),
      address: 'Mississippi Pizza',
      lastDate: '04/20/2020',
      readyDate: '07/20/2020',
      countTrees: 1,
      description:
          'Music, trivia & other all-ages events featured at pizzeria with lounge & vegan & gluten-free pies.',
      category: PlaceCategory.wantToGo,
      starRating: 4,
    ),
    Place(
      id: '12',
      latLng: LatLng(45.420226, -122.740347),
      address: 'Oswego Grill',
      lastDate: '04/20/2020',
      readyDate: '07/20/2020',
      countTrees: 1,
      description:
          'Wood-grilled steakhouse favorites served in a casual, romantic restaurant with a popular happy hour.',
      category: PlaceCategory.wantToGo,
      starRating: 4,
    ),
    Place(
      id: '13',
      latLng: LatLng(45.541202, -122.676432),
      address: 'The Widmer Brothers Brewery',
      lastDate: '04/20/2020',
      readyDate: '07/20/2020',
      countTrees: 1,
      description:
          'Popular, enduring gastropub serving craft beers, sandwiches & eclectic entrees in a laid-back space.',
      category: PlaceCategory.wantToGo,
      starRating: 4,
    ),
    Place(
      id: '14',
      latLng: LatLng(45.559783, -122.924103),
      address: 'TopGolf',
      lastDate: '04/20/2020',
      readyDate: '07/20/2020',
      countTrees: 1,
      description:
          'Sprawling entertainment venue with a high-tech driving range & swanky lounge with drinks & games.',
      category: PlaceCategory.wantToGo,
      starRating: 5,
    ),
    Place(
      id: '15',
      latLng: LatLng(45.485612, -122.784733),
      address: 'Uwajimaya Beaverton',
      lastDate: '04/20/2020',
      readyDate: '07/20/2020',
      countTrees: 1,
      description:
          'Huge Asian grocery outpost stocking meats, produce & prepared foods plus gifts & home goods.',
      category: PlaceCategory.wantToGo,
      starRating: 5,
    ),
  ];

  static const List<String> reviewStrings = [
    'My favorite place in Portland. The employees are wonderful and so is the food. I go here at least once a month!',
    'Staff was very friendly. Great atmosphere and good music. Would reccommend.',
    'Best. Place. In. Town. Period.'
  ];
}
