import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

/// Captures a [RepaintBoundary] referenced by [boundaryKey] into a PNG byte array.
Future<Uint8List> captureBoundaryPng({
  required GlobalKey boundaryKey,
  double pixelRatio = 3,
}) async {
  final context = boundaryKey.currentContext;
  if (context == null) {
    throw StateError('captureBoundaryPng: boundaryKey has no currentContext.');
  }

  final renderObject = context.findRenderObject();
  if (renderObject is! RenderRepaintBoundary) {
    throw StateError('captureBoundaryPng: renderObject is not RepaintBoundary.');
  }

  final image = await renderObject.toImage(pixelRatio: pixelRatio);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) throw StateError('captureBoundaryPng: toByteData failed.');
  return byteData.buffer.asUint8List();
}

/// Shares PNG bytes using the platform share sheet.
Future<void> sharePngBytes({
  required Uint8List pngBytes,
  String fileName = 'dayly.png',
  String? text,
}) async {
  final file = XFile.fromData(
    pngBytes,
    mimeType: 'image/png',
    name: fileName,
  );
  await SharePlus.instance.share(
    ShareParams(files: <XFile>[file], text: text),
  );
}

