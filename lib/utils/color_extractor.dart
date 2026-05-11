import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class ColorExtractor {
  static Future<Color> extractColor(ImageProvider imageProvider) async {
    try {
      final PaletteGenerator paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 20,
      );
      return paletteGenerator.dominantColor?.color ?? const Color(0xFF1DB954);
    } catch (e) {
      return const Color(0xFF1DB954);
    }
  }
}
