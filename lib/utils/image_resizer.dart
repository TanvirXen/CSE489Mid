import 'dart:typed_data';

import 'package:image/image.dart' as img;

Future<Uint8List?> resizeImage(
  Uint8List input, {
  int width = 800,
  int height = 600,
}) async {
  final decoded = img.decodeImage(input);
  if (decoded == null) {
    return null;
  }
  final resized = img.copyResize(
    decoded,
    width: width,
    height: height,
    interpolation: img.Interpolation.cubic,
  );
  return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
}
