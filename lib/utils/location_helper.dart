import 'package:geolocator/geolocator.dart';

Future<Position> resolveCurrentPosition() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw const LocationServiceDisabledException();
  }
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw const PermissionRequestDeniedException();
    }
  }
  if (permission == LocationPermission.deniedForever) {
    throw const PermissionRequestDeniedException();
  }
  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
  );
}

class LocationServiceDisabledException implements Exception {
  const LocationServiceDisabledException();

  @override
  String toString() => 'Location services are disabled.';
}

class PermissionRequestDeniedException implements Exception {
  const PermissionRequestDeniedException();

  @override
  String toString() => 'Location permission denied.';
}
