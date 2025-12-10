import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/landmark.dart';

class LandmarkApi {
  LandmarkApi({http.Client? client}) : _client = client ?? http.Client();

  static final Uri _baseUri = Uri.parse(
    'https://labs.anontech.info/cse489/t3/api.php',
  );

  final http.Client _client;

  Uri get _assetBase => _baseUri.resolve('.');

  String _absoluteImageUrl(String imagePath) {
    if (imagePath.isEmpty) {
      return '';
    }
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    return _assetBase.resolve(imagePath).toString();
  }

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
      final landmark = Landmark.fromJson(map);
      return landmark.copyWith(
        imageUrl: _absoluteImageUrl((map['image'] ?? '').toString()),
      );
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
    _ensureSuccess(response, fallback: 'Failed to create landmark');
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
    _ensureSuccess(response, fallback: 'Failed to update landmark');
  }

  Future<void> deleteLandmark(int id) async {
    final uri = _buildUri({'id': '$id'});
    final response = await _client.delete(uri);
    _ensureSuccess(response, fallback: 'Failed to delete landmark');
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

  Uri _buildUri(Map<String, String> queryParameters) {
    if (queryParameters.isEmpty) {
      return _baseUri;
    }
    final merged = Map<String, String>.from(_baseUri.queryParameters);
    merged.addAll(queryParameters);
    return _baseUri.replace(queryParameters: merged);
  }

  void _ensureSuccess(
    http.BaseResponse response, {
    String fallback = 'Request failed',
    String? body,
  }) {
    if (response.statusCode == 200) return;
    final resolvedBody = body ??
        (response is http.Response ? response.body : null) ??
        '';
    final message = _extractError(resolvedBody) ??
        '$fallback (${response.statusCode})';
    throw Exception(message);
  }

  String? _extractError(String? body) {
    if (body == null || body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final error = decoded['error'] ?? decoded['message'];
        return error?.toString();
      }
    } catch (_) {
      return body.trim().isEmpty ? null : body;
    }
    return null;
  }
}
