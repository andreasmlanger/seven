import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';


Future<Map<String, double>> getGeoLocation() async {
  var status = await Permission.location.request();
  if (status.isGranted) {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
    );
    return {'lat': position.latitude, 'lon': position.longitude};
  } else {
    throw Exception;
  }
}
