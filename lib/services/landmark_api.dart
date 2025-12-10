import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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
      throw Exception('Unable to load landmarks (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Malformed response');
    }
    return decoded.map((raw) {
      final map = Map<String, dynamic>.from(raw as Map);
      final landmark = Landmark.fromJson(map);
      final resolved = landmark.copyWith(
        imageUrl: _absoluteImageUrl((map['image'] ?? '').toString()),
      );
      return resolved;
    }).toList();
  }

  Future<int> createLandmark(LandmarkDraft draft) async {
    final request = http.MultipartRequest('POST', _baseUri);
    _assignCommonFields(request, draft);
    if (draft.hasImage) {
      request.files.add(
        _buildMultipartImage(draft.imageBytes!, fileName: draft.imageName),
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
    if (draft.hasImage) {
      await _replaceLandmarkWithNewImage(draft);
      return;
    }
    final request = http.MultipartRequest('PUT', _baseUri)
      ..fields.addAll(_buildCommonFields(draft))
      ..fields['id'] = '${draft.id}';
    final response =
        await http.Response.fromStream(await _client.send(request));
    _ensureSuccess(response, fallback: 'Failed to update landmark');
  }

  Future<void> deleteLandmark(int id) async {
    final uri = _buildUri({'id': id.toString()});
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

  http.MultipartFile _buildMultipartImage(Uint8List bytes, {String? fileName}) {
    final mediaType = _detectMediaType(bytes, fileName: fileName);
    if (mediaType == null) {
      throw Exception('Unsupported image format. Use JPG, PNG, GIF or WebP.');
    }
    final safeName = _normalizedFileName(fileName, mediaType);
    return http.MultipartFile.fromBytes(
      'image',
      bytes,
      filename: safeName,
      contentType: mediaType,
    );
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

  MediaType? _detectMediaType(Uint8List bytes, {String? fileName}) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return MediaType('image', 'jpeg');
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return MediaType('image', 'png');
    }
    if (bytes.length >= 6) {
      final signature = String.fromCharCodes(bytes.sublist(0, 6));
      if (signature.startsWith('GIF8')) {
        return MediaType('image', 'gif');
      }
    }
    if (bytes.length >= 12) {
      final riff = String.fromCharCodes(bytes.sublist(0, 4));
      final webp = String.fromCharCodes(bytes.sublist(8, 12));
      if (riff == 'RIFF' && webp == 'WEBP') {
        return MediaType('image', 'webp');
      }
    }
    final name = fileName?.toLowerCase() ?? '';
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    if (name.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (name.endsWith('.gif')) {
      return MediaType('image', 'gif');
    }
    if (name.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    return null;
  }

  String _normalizedFileName(String? original, MediaType mediaType) {
    final extension = switch (mediaType.subtype) {
      'jpeg' => '.jpg',
      'png' => '.png',
      'gif' => '.gif',
      'webp' => '.webp',
      _ => '.bin',
    };
    final raw = (original?.trim().isNotEmpty ?? false)
        ? original!.trim()
        : 'image$extension';
    final sanitized = raw.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final lower = sanitized.toLowerCase();
    if (lower.endsWith(extension)) {
      return sanitized;
    }
    final dotIndex = sanitized.lastIndexOf('.');
    final base = dotIndex == -1 ? sanitized : sanitized.substring(0, dotIndex);
    return '$base$extension';
  }

  Future<void> _replaceLandmarkWithNewImage(LandmarkDraft draft) async {
    final replacement = LandmarkDraft(
      title: draft.title,
      lat: draft.lat,
      lon: draft.lon,
      imageBytes: draft.imageBytes,
      imageName: draft.imageName,
    );
    int? newId;
    try {
      newId = await createLandmark(replacement);
      await deleteLandmark(draft.id!);
      draft.id = newId;
    } catch (error) {
      if (newId != null) {
        try {
          await deleteLandmark(newId);
        } catch (_) {}
      }
      rethrow;
    }
  }
}
