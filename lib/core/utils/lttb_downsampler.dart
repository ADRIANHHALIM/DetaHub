// lib/core/utils/lttb_downsampler.dart
//
// Pure Dart implementation of the Largest-Triangle-Three-Buckets (LTTB) algorithm.
//
// Reference:
//   Sveinn Steinarsson (2013). "Downsampling Time Series for Visual Representation."
//   MSc Thesis, University of Iceland. https://skemman.is/handle/1946/15343
//
// Algorithm overview (O(n) time, O(threshold) space):
//   1. Always keep the first and last data points.
//   2. Partition the interior data into (threshold - 2) equal-width buckets.
//   3. For each bucket, select the point that forms the largest triangle area
//      with the previously selected point and the average of the next bucket.
//   4. The result preserves the visual shape of the original series — far
//      superior to naive uniform sampling for irregular or peaked time-series.
//
// Usage:
//   final points = records.map((r) => ChartPoint(
//     x: r.timestamp.millisecondsSinceEpoch.toDouble(),
//     y: r.temperature ?? 0.0,
//   )).toList();
//   final downsampled = LttbDownsampler.downsample(points, threshold: 150);

/// A 2-D point for chart rendering.
///
/// [x] is typically epoch milliseconds (as a double) so it maps directly
/// to fl_chart's [FlSpot.x]. [y] is the metric value.
class ChartPoint {
  final double x;
  final double y;

  const ChartPoint(this.x, this.y);

  @override
  String toString() => 'ChartPoint($x, $y)';

  @override
  bool operator ==(Object other) =>
      other is ChartPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// Stateless utility class exposing the LTTB downsampling algorithm.
abstract final class LttbDownsampler {
  /// Reduces [data] to at most [threshold] representative points using LTTB.
  ///
  /// Parameters:
  ///   [data]      — Source points in ascending x order (required).
  ///   [threshold] — Desired output count, typically 100–200 for fl_chart.
  ///
  /// Returns the original list unchanged if:
  ///   - [data] has fewer than or equal to [threshold] points.
  ///   - [threshold] is less than 3 (cannot form a triangle).
  ///
  /// This method is pure and free of Flutter/UI dependencies — safe to call
  /// from a background Dart Isolate.
  static List<ChartPoint> downsample(
    List<ChartPoint> data, {
    int threshold = 150,
  }) {
    final n = data.length;

    // Guard: no downsampling needed.
    if (threshold >= n || threshold < 3) return data;

    // Pre-allocate with nullable to allow index-based assignment.
    // We guarantee all slots are filled before returning.
    final sampled = List<ChartPoint?>.filled(threshold, null);

    // Step 1 — Always include the first point.
    sampled[0] = data[0];

    // Step 2 — Bucket parameters.
    // We have (threshold - 2) buckets for the interior data [1 .. n-2].
    // Each bucket spans roughly (n - 2) / (threshold - 2) raw points.
    final every = (n - 2) / (threshold - 2);

    int a = 0; // Index of the last selected point.

    for (int i = 0; i < threshold - 2; i++) {
      // --- Compute the average point of the NEXT bucket (look-ahead) ---
      //
      // The next bucket runs from bucketStart+1 to bucketEnd (inclusive).
      // We compute the centroid of all points in that bucket, which acts
      // as a "representative" for the LTTB triangle calculation.
      final nextBucketStart = ((i + 1) * every + 1).floor();
      final nextBucketEnd =
          ((i + 2) * every + 1).floor().clamp(0, n); // exclusive

      double avgX = 0;
      double avgY = 0;
      final nextBucketSize = nextBucketEnd - nextBucketStart;

      for (int j = nextBucketStart; j < nextBucketEnd; j++) {
        avgX += data[j].x;
        avgY += data[j].y;
      }
      avgX /= nextBucketSize;
      avgY /= nextBucketSize;

      // --- Find the point in the CURRENT bucket with the largest triangle ---
      //
      // Triangle vertices:
      //   A = previously selected point (index a)
      //   B = candidate point in current bucket
      //   C = centroid of next bucket (avgX, avgY)
      //
      // Area = 0.5 * |Ax(By - Cy) + Bx(Cy - Ay) + Cx(Ay - By)|
      // We skip the 0.5 factor since we only compare areas.
      final currentBucketStart = (i * every + 1).floor();
      final currentBucketEnd =
          ((i + 1) * every + 1).floor().clamp(0, n); // exclusive

      double maxArea = -1;
      int maxAreaIdx = currentBucketStart;

      final pointA = data[a];

      for (int j = currentBucketStart; j < currentBucketEnd; j++) {
        final pointB = data[j];

        // Triangle area × 2 (sign-agnostic, so we use absolute value).
        final area = ((pointA.x - avgX) * (pointB.y - pointA.y) -
                (pointA.x - pointB.x) * (avgY - pointA.y))
            .abs();

        if (area > maxArea) {
          maxArea = area;
          maxAreaIdx = j;
        }
      }

      // Commit the winning point for this bucket.
      sampled[i + 1] = data[maxAreaIdx];
      a = maxAreaIdx; // Advance the "previous selected" pointer.
    }

    // Step 3 — Always include the last point.
    sampled[threshold - 1] = data[n - 1];

    // Cast: all slots guaranteed non-null (first filled in step 1,
    // interior slots filled in the loop, last filled in step 3).
    return sampled.cast<ChartPoint>();
  }
}
