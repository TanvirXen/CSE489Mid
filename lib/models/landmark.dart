import 'dart:typed_data';

class Landmark {
  const Landmark({
    required this.id,
    required this.title,
    required this.lat,
    required this.lon,
    required this.imageUrl,
  });

  final int id;
  final String title;
  final double lat;
  final double lon;
  final String imageUrl;

  String get latLonLabel =>
      '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';

  Landmark copyWith({
    int? id,
    String? title,
    double? lat,
    double? lon,
    String? imageUrl,
  }) => Landmark(
    id: id ?? this.id,
    title: title ?? this.title,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    imageUrl: imageUrl ?? this.imageUrl,
  );

  factory Landmark.fromJson(Map<String, dynamic> json) {
    final rawLat = json['lat'];
    final rawLon = json['lon'];
    final rawImage = json['image'] ?? '';
    return Landmark(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: (json['title'] ?? '').toString(),
      lat: rawLat is num ? rawLat.toDouble() : double.tryParse('$rawLat') ?? 0,
      lon: rawLon is num ? rawLon.toDouble() : double.tryParse('$rawLon') ?? 0,
      imageUrl: rawImage.toString(),
    );
  }
}

class LandmarkDraft {
  LandmarkDraft({
    this.id,
    this.title = '',
    this.lat,
    this.lon,
    this.imageBytes,
    this.imageName,
    this.existingImageUrl,
  });

  int? id;
  String title;
  double? lat;
  double? lon;
  Uint8List? imageBytes;
  String? imageName;
  String? existingImageUrl;

  bool get hasImage => imageBytes != null && imageBytes!.isNotEmpty;

  bool get isComplete =>
      title.trim().isNotEmpty &&
      lat != null &&
      lon != null &&
      lat!.isFinite &&
      lon!.isFinite;

  LandmarkDraft copyWith({
    int? id,
    String? title,
    double? lat,
    double? lon,
    Uint8List? imageBytes,
    String? imageName,
    String? existingImageUrl,
  }) {
    return LandmarkDraft(
      id: id ?? this.id,
      title: title ?? this.title,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      imageBytes: imageBytes ?? this.imageBytes,
      imageName: imageName ?? this.imageName,
      existingImageUrl: existingImageUrl ?? this.existingImageUrl,
    );
  }

  factory LandmarkDraft.fromLandmark(Landmark landmark) {
    return LandmarkDraft(
      id: landmark.id,
      title: landmark.title,
      lat: landmark.lat,
      lon: landmark.lon,
      existingImageUrl: landmark.imageUrl,
    );
  }

  void clearImage() {
    imageBytes = null;
    imageName = null;
    existingImageUrl = null;
  }
}
