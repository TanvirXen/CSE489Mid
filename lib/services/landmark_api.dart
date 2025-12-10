import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/landmark.dart';

class LandmarkApi {
  LandmarkApi({http.Client? client}) : _client = client ?? http.Client();

  static final Uri _baseUri = Uri.parse(
    'https://labs.anontech.info/cse489/t3/api.php',
  );

  final http.Client _client;

  Future<List<Landmark>> fetchLandmarks() async {
    final response = await _client.get(_baseUri);
    if (response.statusCode != 200) {
      throw Exception('Unable to load landmarks');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Malformed response');
    }
    return decoded.map((raw) {
      final map = Map<String, dynamic>.from(raw as Map);
      return Landmark.fromJson(map);
    }).toList();
  }
}
