import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_test/flutter_test.dart';

/// Golden images may differ by a few anti-aliased pixels between machines
/// (font rasteriser versions). Allow a tiny difference; shaping or layout
/// errors change far more than this.
const double _tolerance = 0.005; // 0.5% of pixels

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (goldenFileComparator is LocalFileComparator) {
    final base = goldenFileComparator as LocalFileComparator;
    goldenFileComparator = _TolerantComparator(base.basedir.resolve('placeholder.dart'));
  }
  await testMain();
}

class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(imageBytes, await getGoldenBytes(golden));
    if (result.passed || result.diffPercent <= _tolerance) return true;
    final error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(error);
  }
}
