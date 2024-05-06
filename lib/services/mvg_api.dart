import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:seven/services/location.dart';


// MVG APIs: https://pypi.org/project/mvg/
const String FIB = 'https://www.mvg.de/api/fib/v2';
const String FIB_NEARBY = '$FIB/station/nearby';
const String FIB_DEPART = '$FIB/departure';

const List<String> HOME_DESTINATIONS = ['Aying', 'Kreuzstraße'];
const List<String> WORK_DESTINATIONS = ['Wolfratshausen'];

// Stations of S7 between Ostbahnhof and Mittersendling
const List <Map<String, dynamic>> STATIONS = [
  {'name': 'München, Ostbahnhof', 'destination': WORK_DESTINATIONS},
  {'name': 'Rosenheimer Platz', 'destination': WORK_DESTINATIONS},
  {'name': 'Isartor', 'destination': WORK_DESTINATIONS},
  {'name': 'Marienplatz', 'destination': WORK_DESTINATIONS},
  {'name': 'Karlsplatz', 'destination': WORK_DESTINATIONS},
  {'name': 'München Hbf', 'destination': WORK_DESTINATIONS},
  {'name': 'Hackerbrücke', 'destination': WORK_DESTINATIONS},
  {'name': 'Donnersberger Brücke', 'destination': WORK_DESTINATIONS},
  {'name': 'Heimeranplatz', 'destination': HOME_DESTINATIONS},
  {'name': 'Harras', 'destination': HOME_DESTINATIONS},
  {'name': 'Mittersendling', 'destination': HOME_DESTINATIONS},
];

Future<Map<String, dynamic>> fetchNearbyStation(lat, lon) async {
  //lat = 48.12832633085423;  // only for debug
  //lon = 11.597135944262709;  // only for debug

  final String apiCall = '$FIB_NEARBY?latitude=$lat&longitude=$lon';
  final Uri url = Uri.parse(apiCall);
  try {
    final http.Response response = await http.get(url);
    List<dynamic> dataList = jsonDecode(response.body);
    for (var item in dataList) {
      for (var station in STATIONS) {
        if (item['name'] == station['name']) {
          return {
            'name': item['name'],
            'globalId': item['globalId'],
            'distanceInMeters': item['distanceInMeters'],
            'destination': station['destination']!,
          };
        }
      };
    }
  } catch (e) {
    print(e);
  }
  throw Exception;
}

Future<Map<String, dynamic>> fetchNextDeparture(globalId, destination) async {
  final String apiCall = '$FIB_DEPART?globalId=$globalId';
  final Uri url = Uri.parse(apiCall);
  print(url);
  try {
    final http.Response response = await http.get(url);
    List<dynamic> dataList = jsonDecode(response.body);
    for (var item in dataList) {
      if (item['label'] == 'S7' && destination.contains(item['destination']) && !item['cancelled']) {
        return {
          'plannedDepartureTime': DateTime.fromMillisecondsSinceEpoch(item['plannedDepartureTime']),
          'realtimeDepartureTime': DateTime.fromMillisecondsSinceEpoch(item['realtimeDepartureTime']),
        };
      }
    }
  } catch (e) {
    print(e);
  }
  throw Exception;
}

Future<Map<String, dynamic>> getNextDeparture() async {
  // Find GPS location
  Map<String, double> geoLocation = {};
  try {
    geoLocation = await getGeoLocation();
  } catch (e) {
    return {'message': 'Waiting for GPS', 'loading': true};
  }

  // Find nearest S7 station
  Map<String, dynamic> station = {};
  try {
    station = await fetchNearbyStation(geoLocation['lat']!, geoLocation['lon']!);
  } catch (e) {
    return {'message': 'No S7 nearby!', 'loading': false};
  }

  // Find next departure time
  Map<String, dynamic> departure = {};
  try {
    departure = await fetchNextDeparture(station['globalId'], station['destination']);
  } catch (e) {
    return {'message': 'No S7 scheduled!', 'loading': false};
  }

  // Return departure information
  return {
    'name': station['name'],
    'plannedDepartureTime': departure['plannedDepartureTime'],
    'realtimeDepartureTime': departure['realtimeDepartureTime'],
    'delayInMinutes': departure['realtimeDepartureTime'].difference(departure['plannedDepartureTime']).inMinutes,
    'distanceInMeters': station['distanceInMeters'],
  };
}
