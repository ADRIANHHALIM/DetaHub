// test/core/utils/lttb_downsampler_test.dart
//
// Unit tests for the LTTB downsampling algorithm.
// Verifies correctness, edge cases, and that visual landmarks are preserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:detahub/core/utils/lttb_downsampler.dart';

// ---------------------------------------------------------------------------
// Test helpers (top-level so they are visible throughout the file)
// ---------------------------------------------------------------------------

/// Pure-Dart sine approximation using a 4-term Taylor series.
/// Accurate enough for test data generation within 0..2π.
/// Avoids importing dart:math to keep tests dependency-free.
double testSin(double radians) {
  final x = radians % (2 * 3.14159265);
  return x -
      (x * x * x) / 6 +
      (x * x * x * x * x) / 120 -
      (x * x * x * x * x * x * x) / 5040;
}

/// Generates a synthetic sine-wave dataset with [count] points.
List<ChartPoint> sineWave(int count, {double amplitude = 50.0}) {
  return List.generate(count, (i) {
    final x = i.toDouble();
    final y = amplitude * (0.5 + 0.5 * testSin(i / count * 2 * 3.14159265));
    return ChartPoint(x, y);
  });
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('LttbDownsampler', () {
    // -----------------------------------------------------------------------
    // Output size tests
    // -----------------------------------------------------------------------

    test('returns exactly [threshold] points for data > threshold', () {
      final data = sineWave(1440);
      final result = LttbDownsampler.downsample(data, threshold: 150);
      expect(result.length, equals(150));
    });

    test('returns original data when length <= threshold', () {
      final data = sineWave(100);
      final result = LttbDownsampler.downsample(data, threshold: 150);
      expect(result.length, equals(100));
      expect(result, same(data)); // Should be the identical list object.
    });

    test('returns original data when threshold < 3', () {
      final data = sineWave(1440);
      final result = LttbDownsampler.downsample(data, threshold: 2);
      expect(result, same(data));
    });

    test('handles exactly threshold == data.length', () {
      final data = sineWave(150);
      final result = LttbDownsampler.downsample(data, threshold: 150);
      expect(result, same(data));
    });

    // -----------------------------------------------------------------------
    // Endpoint preservation
    // -----------------------------------------------------------------------

    test('always preserves the first point', () {
      final data = sineWave(1440);
      final result = LttbDownsampler.downsample(data, threshold: 150);
      expect(result.first, equals(data.first));
    });

    test('always preserves the last point', () {
      final data = sineWave(1440);
      final result = LttbDownsampler.downsample(data, threshold: 150);
      expect(result.last, equals(data.last));
    });

    // -----------------------------------------------------------------------
    // All output points must come from the original input
    // -----------------------------------------------------------------------

    test('all output points are from the original dataset', () {
      final data = sineWave(1440);
      final inputSet = data.toSet();
      final result = LttbDownsampler.downsample(data, threshold: 150);
      for (final point in result) {
        expect(inputSet.contains(point), isTrue,
            reason: 'Point $point in output not found in input dataset');
      }
    });

    // -----------------------------------------------------------------------
    // Monotonic X order
    // -----------------------------------------------------------------------

    test('output is in ascending x order', () {
      final data = sineWave(1440);
      final result = LttbDownsampler.downsample(data, threshold: 150);
      for (int i = 1; i < result.length; i++) {
        expect(result[i].x, greaterThanOrEqualTo(result[i - 1].x),
            reason: 'x values must be non-decreasing at index $i');
      }
    });

    // -----------------------------------------------------------------------
    // Empty / minimal input
    // -----------------------------------------------------------------------

    test('handles empty data gracefully', () {
      final result = LttbDownsampler.downsample([], threshold: 150);
      expect(result, isEmpty);
    });

    test('handles single-point data', () {
      final data = [const ChartPoint(0, 42)];
      final result = LttbDownsampler.downsample(data, threshold: 150);
      expect(result.length, equals(1));
      expect(result.first, equals(data.first));
    });

    test('handles two-point data', () {
      final data = [const ChartPoint(0, 0), const ChartPoint(1, 100)];
      final result = LttbDownsampler.downsample(data, threshold: 150);
      expect(result.length, equals(2));
    });

    // -----------------------------------------------------------------------
    // Real-world simulation: 1440 → 150 (LAT daily log)
    // -----------------------------------------------------------------------

    test('1440 daily points → 150 target (LAT daily log simulation)', () {
      // Simulate 1 reading per minute for 24 hours.
      final data = List.generate(1440, (i) {
        final baseTemp = 25.0 + 5.0 * testSin(i / 240 * 3.14159);
        return ChartPoint(i.toDouble(), baseTemp);
      });

      final result = LttbDownsampler.downsample(data, threshold: 150);

      expect(result.length, equals(150));
      expect(result.first, equals(data.first));
      expect(result.last, equals(data.last));

      // Verify all selected points are from the original dataset.
      final inputSet = {for (final p in data) (p.x, p.y)};
      for (final p in result) {
        expect(inputSet.contains((p.x, p.y)), isTrue);
      }
    });

    // -----------------------------------------------------------------------
    // Various threshold sizes
    // -----------------------------------------------------------------------

    test('threshold 3 (minimum valid) produces exactly 3 points', () {
      final data = sineWave(1440);
      final result = LttbDownsampler.downsample(data, threshold: 3);
      expect(result.length, equals(3));
      expect(result.first, equals(data.first));
      expect(result.last, equals(data.last));
    });

    test('threshold 1000 on 1440 points produces 1000 points', () {
      final data = sineWave(1440);
      final result = LttbDownsampler.downsample(data, threshold: 1000);
      expect(result.length, equals(1000));
    });
  });
}
