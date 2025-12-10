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

  Future<int> createLandmark(LandmarkDraft draft) async {
    final request = http.MultipartRequest('POST', _baseUri);
    _assignCommonFields(request, draft);
    final image = draft.imageBytes;
    if (image != null && image.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          image,
          filename: draft.imageName ?? 'upload.jpg',
        ),
      );
    }
    final response =
        await http.Response.fromStream(await _client.send(request));
    if (response.statusCode != 200) {
      throw Exception('Failed to create landmark');
    }
    final decoded = jsonDecode(response.body);
    final rawId = decoded is Map ? decoded['id'] : null;
    return int.tryParse(rawId?.toString() ?? '') ?? 0;
  }

  Future<void> updateLandmark(LandmarkDraft draft) async {
    if (draft.id == null) {
      throw ArgumentError('Cannot update without an id');
    }
    final request = http.MultipartRequest('PUT', _baseUri)
      ..fields['id'] = '${draft.id}';
    _assignCommonFields(request, draft);
    final image = draft.imageBytes;
    if (image != null && image.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          image,
          filename: draft.imageName ?? 'upload.jpg',
        ),
      );
    }
    final response =
        await http.Response.fromStream(await _client.send(request));
    if (response.statusCode != 200) {
      throw Exception('Failed to update landmark');
    }
  }

  Future<void> deleteLandmark(int id) async {
    final uri = _baseUri.replace(queryParameters: {'id': '$id'});
    final response = await _client.delete(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete landmark');
    }
  }

  void _assignCommonFields(http.MultipartRequest request, LandmarkDraft draft) {
    request.fields.addAll(_buildCommonFields(draft));
  }

  Map<String, String> _buildCommonFields(LandmarkDraft draft) {
    return {
      'title': draft.title,
      'lat': draft.lat?.toString() ?? '',
      'lon': draft.lon?.toString() ?? '',
    };
  }
}
