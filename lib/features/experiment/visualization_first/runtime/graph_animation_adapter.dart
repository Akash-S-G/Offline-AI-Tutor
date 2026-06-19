import '../graphs/animated_graph_profile.dart';
import '../graphs/animated_graph_profile_registry.dart';

class GraphAnimationAdapter {
  const GraphAnimationAdapter();

  AnimatedGraphProfile profileFor(String graphType) {
    return AnimatedGraphProfileRegistry.all.firstWhere(
      (profile) => profile.graphType == graphType,
      orElse: () => AnimatedGraphProfileRegistry.lineGraph,
    );
  }

  Map<String, dynamic> animationMetadataFor(String graphType) {
    final profile = profileFor(graphType);
    return {
      'graphType': profile.graphType,
      'enterAnimation': profile.enterAnimation,
      'updateAnimation': profile.updateAnimation,
      'durationSeconds': profile.animationDurationSeconds,
      'highlightsLatestData': profile.highlightsLatestData,
    };
  }
}
