import 'animated_graph_profile.dart';

class AnimatedGraphProfileRegistry {
  const AnimatedGraphProfileRegistry._();

  static const lineGraph = AnimatedGraphProfile(
    graphType: 'lineGraph',
    enterAnimation: 'draw_line_from_start',
    updateAnimation: 'pulse_latest_point',
  );

  static const scatterPlot = AnimatedGraphProfile(
    graphType: 'scatterPlot',
    enterAnimation: 'points_scale_in',
    updateAnimation: 'pulse_new_point',
  );

  static const barChart = AnimatedGraphProfile(
    graphType: 'barChart',
    enterAnimation: 'bars_grow_from_zero',
    updateAnimation: 'animate_bar_height',
  );

  static const oscilloscope = AnimatedGraphProfile(
    graphType: 'oscilloscope',
    enterAnimation: 'waveform_sweep_in',
    updateAnimation: 'live_waveform_scroll',
    animationDurationSeconds: 0.2,
  );

  static const all = {lineGraph, scatterPlot, barChart, oscilloscope};
}
