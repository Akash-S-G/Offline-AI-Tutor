/// A single named state in a simulation (e.g. 'rain', 'cloud_forming').
class SimulationState {
  final String id;
  final String label;
  final Map<String, dynamic> metadata;

  const SimulationState({
    required this.id,
    required this.label,
    this.metadata = const {},
  });

  factory SimulationState.fromJson(Map<String, dynamic> json) {
    return SimulationState(
      id: json['id'] as String,
      label: json['label'] as String? ?? json['id'] as String,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  factory SimulationState.fromString(String id) {
    return SimulationState(id: id, label: id);
  }

  @override
  String toString() => 'SimulationState($id)';

  @override
  bool operator ==(Object other) => other is SimulationState && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
