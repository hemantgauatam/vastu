// Shared map/chakra geometry used by painters, preview and PDF exports.
import 'dart:math' as math;
import 'dart:ui' show Size;

/// For 45 Devata and Vastu Purush, the inner chakra stays within the fitted
/// map and touches its limiting left/right edges. The labelled outer circle
/// may remain outside the rectangular map, matching the requested layout.
const double k45DevataOuterBandInnerRatio = 0.92;
// The dedicated 45 Devata outer ring is intentionally thinner/compact. Its
// painter uses a 0.49 canvas radius and a 0.86 inner-radius ratio, therefore
// the visible joining diameter is 2 x 0.49 x 0.86 = 0.8428.
const double k45DevataOuterRingInnerRadiusRatio = 0.86;
const double k45DevataRingJoinRatio = 0.8428;
// Measured from the supplied complete 45 Devata artwork: the inner edge of
// its labelled direction band is 89.7% of the visible outer diameter. The
// placement method remains the same as Vastu Purush, but each artwork needs
// its own measured boundary ratio for an exact map touch.
const double k45DevataMapTouchInnerRatio = 0.897;
// Measured from the cropped vastu_p1.png artwork. Its inner direction-band
// circle is 82.7% of the complete visible chakra diameter.
const double kVastuPurushOuterBandInnerRatio = 0.827;

// The supplied inner artwork is intentionally a little larger than the map
// width. Keeping this separate from the map/outer-ring ratio prevents a scale
// correction from changing both circles at the same time.
// The PNG retains a few pixels of white antialiased padding around its visible
// circle. This calibrated overscan makes the actual dark circumference meet
// the generated outer-ring stroke with no visible gap.
// The cropped PNG's visible circumference is ~99.4% of its normalized square.
// 0.85 therefore lands it on the generated ring's 0.8428 join diameter with
// only an antialias-safe sub-pixel overlap (no visible gap or intrusion).
const double k45DevataInnerArtworkRatio = 0.85;
const double kVastuPurushInnerArtworkRatio = 0.827;

double chakraMapTouchInnerRatio(String chakraId) => switch (chakraId) {
      // The map touches the deeper structural circle, not the thin labelled
      // direction-band boundary at 0.92.
      '45-devata' => k45DevataMapTouchInnerRatio,
      'vastu-purush' || 'vastu-purush-inner' => kVastuPurushOuterBandInnerRatio,
      _ => 1.0,
    };

double chakraInnerArtworkRatio(String chakraId) => switch (chakraId) {
      '45-devata' => k45DevataInnerArtworkRatio,
      'vastu-purush' || 'vastu-purush-inner' => kVastuPurushInnerArtworkRatio,
      _ => 1.0,
    };

double chakraSideForMapEdges(String chakraId, Size mapSize) {
  final innerRatio = chakraMapTouchInnerRatio(chakraId);
  // Match the reference layout: the chakra's inner circle touches the map's
  // shorter pair of edges, while the rectangular map continues beyond the
  // circle along its longer axis. The labelled outer circle may therefore sit
  // outside the map on the shorter axis.
  return math.min(mapSize.width, mapSize.height) / innerRatio;
}
