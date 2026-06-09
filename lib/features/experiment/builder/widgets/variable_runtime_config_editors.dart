import 'package:flutter/material.dart';

import '../models/builder_variable.dart';

typedef VariableRuntimeConfigChanged =
    void Function(Map<String, dynamic> config);

class RuntimeVariableConfigEditor extends StatelessWidget {
  final String variableType;
  final List<BuilderVariable> variables;
  final Map<String, dynamic> config;
  final String? currentVariableId;
  final VariableRuntimeConfigChanged onChanged;

  const RuntimeVariableConfigEditor({
    super.key,
    required this.variableType,
    required this.variables,
    required this.config,
    required this.onChanged,
    this.currentVariableId,
  });

  @override
  Widget build(BuildContext context) {
    final candidates = variables
        .where((variable) => variable.id != currentVariableId)
        .toList(growable: false);
    switch (variableType) {
      case 'elapsedTime':
        return ElapsedTimeVariableEditor(config: config, onChanged: onChanged);
      case 'countdown':
        return CountdownVariableEditor(config: config, onChanged: onChanged);
      case 'interval':
        return IntervalVariableEditor(config: config, onChanged: onChanged);
      case 'average':
      case 'minimum':
      case 'maximum':
        return MultiDependencyVariableEditor(
          title: _titleFor(variableType),
          variables: candidates,
          config: config,
          onChanged: onChanged,
        );
      case 'distance':
        return PairDependencyVariableEditor(
          title: 'Distance',
          firstLabel: 'Speed Variable',
          firstKey: 'speedVariable',
          secondLabel: 'Time Variable',
          secondKey: 'timeVariable',
          variables: candidates,
          config: config,
          onChanged: onChanged,
        );
      case 'velocity':
        return PairDependencyVariableEditor(
          title: 'Velocity',
          firstLabel: 'Distance Variable',
          firstKey: 'distanceVariable',
          secondLabel: 'Time Variable',
          secondKey: 'timeVariable',
          variables: candidates,
          config: config,
          onChanged: onChanged,
        );
      case 'acceleration':
        return PairDependencyVariableEditor(
          title: 'Acceleration',
          firstLabel: 'Velocity Variable',
          firstKey: 'velocityVariable',
          secondLabel: 'Time Variable',
          secondKey: 'timeVariable',
          variables: candidates,
          config: config,
          onChanged: onChanged,
        );
      case 'force':
        return PairDependencyVariableEditor(
          title: 'Force',
          firstLabel: 'Mass Variable',
          firstKey: 'massVariable',
          secondLabel: 'Acceleration Variable',
          secondKey: 'accelerationVariable',
          variables: candidates,
          config: config,
          onChanged: onChanged,
        );
      case 'power':
        return PairDependencyVariableEditor(
          title: 'Power',
          firstLabel: 'Force Variable',
          firstKey: 'forceVariable',
          secondLabel: 'Velocity Variable',
          secondKey: 'velocityVariable',
          variables: candidates,
          config: config,
          onChanged: onChanged,
        );
      case 'energy':
        return PairDependencyVariableEditor(
          title: 'Energy',
          firstLabel: 'Power Variable',
          firstKey: 'powerVariable',
          secondLabel: 'Time Variable',
          secondKey: 'timeVariable',
          variables: candidates,
          config: config,
          onChanged: onChanged,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _titleFor(String type) {
    switch (type) {
      case 'average':
        return 'Average';
      case 'minimum':
        return 'Minimum';
      case 'maximum':
        return 'Maximum';
      default:
        return type;
    }
  }
}

class ElapsedTimeVariableEditor extends StatelessWidget {
  final Map<String, dynamic> config;
  final VariableRuntimeConfigChanged onChanged;

  const ElapsedTimeVariableEditor({
    super.key,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _ConfigSection(
      title: 'Elapsed Time',
      children: [
        _NumberConfigField(
          label: 'Start Value',
          value: config['startValue'] ?? 0,
          onChanged: (value) => onChanged({...config, 'startValue': value}),
        ),
      ],
    );
  }
}

class CountdownVariableEditor extends StatelessWidget {
  final Map<String, dynamic> config;
  final VariableRuntimeConfigChanged onChanged;

  const CountdownVariableEditor({
    super.key,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _ConfigSection(
      title: 'Countdown',
      children: [
        _NumberConfigField(
          label: 'Start Value',
          value: config['startValue'] ?? 60,
          onChanged: (value) => onChanged({...config, 'startValue': value}),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Auto Start'),
          value: config['autoStart'] != false,
          onChanged: (value) => onChanged({...config, 'autoStart': value}),
        ),
      ],
    );
  }
}

class IntervalVariableEditor extends StatelessWidget {
  final Map<String, dynamic> config;
  final VariableRuntimeConfigChanged onChanged;

  const IntervalVariableEditor({
    super.key,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _ConfigSection(
      title: 'Interval',
      children: [
        _NumberConfigField(
          label: 'Interval Seconds',
          value: config['intervalSeconds'] ?? 1,
          onChanged: (value) =>
              onChanged({...config, 'intervalSeconds': value}),
        ),
      ],
    );
  }
}

class MultiDependencyVariableEditor extends StatelessWidget {
  final String title;
  final List<BuilderVariable> variables;
  final Map<String, dynamic> config;
  final VariableRuntimeConfigChanged onChanged;

  const MultiDependencyVariableEditor({
    super.key,
    required this.title,
    required this.variables,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = _dependencies.toSet();
    return _ConfigSection(
      title: title,
      children: [
        ...variables.map((variable) {
          return CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(variable.name),
            subtitle: Text(variable.id),
            value: selected.contains(variable.id),
            onChanged: (checked) {
              final next = [...selected];
              if (checked == true) {
                next.add(variable.id);
              } else {
                next.remove(variable.id);
              }
              onChanged({...config, 'dependencies': next});
            },
          );
        }),
        DependencyTreePreview(
          formulaName: title,
          dependencyIds: _dependencies,
          variables: variables,
        ),
      ],
    );
  }

  List<String> get _dependencies {
    final value = config['dependencies'];
    if (value is List) {
      return value.map((entry) => entry.toString()).toList(growable: false);
    }
    return const [];
  }
}

class PairDependencyVariableEditor extends StatelessWidget {
  final String title;
  final String firstLabel;
  final String firstKey;
  final String secondLabel;
  final String secondKey;
  final List<BuilderVariable> variables;
  final Map<String, dynamic> config;
  final VariableRuntimeConfigChanged onChanged;

  const PairDependencyVariableEditor({
    super.key,
    required this.title,
    required this.firstLabel,
    required this.firstKey,
    required this.secondLabel,
    required this.secondKey,
    required this.variables,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _ConfigSection(
      title: title,
      children: [
        _VariableDropdown(
          label: firstLabel,
          variables: variables,
          value: config[firstKey]?.toString(),
          onChanged: (value) => onChanged({...config, firstKey: value}),
        ),
        _VariableDropdown(
          label: secondLabel,
          variables: variables,
          value: config[secondKey]?.toString(),
          onChanged: (value) => onChanged({...config, secondKey: value}),
        ),
        DependencyTreePreview(
          formulaName: title,
          dependencyIds: [
            config[firstKey]?.toString(),
            config[secondKey]?.toString(),
          ].whereType<String>().where((id) => id.isNotEmpty).toList(),
          variables: variables,
        ),
      ],
    );
  }
}

class DependencyTreePreview extends StatelessWidget {
  final String formulaName;
  final List<String> dependencyIds;
  final List<BuilderVariable> variables;

  const DependencyTreePreview({
    super.key,
    required this.formulaName,
    required this.dependencyIds,
    required this.variables,
  });

  @override
  Widget build(BuildContext context) {
    if (dependencyIds.isEmpty) return const SizedBox.shrink();
    final namesById = {
      for (final variable in variables) variable.id: variable.name,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formulaName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          ...dependencyIds.map((id) {
            return Text('├─ ${namesById[id] ?? id}');
          }),
        ],
      ),
    );
  }
}

class _ConfigSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ConfigSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...children.expand((child) => [child, const SizedBox(height: 12)]),
      ],
    );
  }
}

class _NumberConfigField extends StatefulWidget {
  final String label;
  final dynamic value;
  final ValueChanged<double> onChanged;

  const _NumberConfigField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_NumberConfigField> createState() => _NumberConfigFieldState();
}

class _NumberConfigFieldState extends State<_NumberConfigField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(_NumberConfigField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final value = widget.value.toString();
    if (value != oldWidget.value.toString() && value != _controller.text) {
      _controller.text = value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) {
        final parsed = double.tryParse(value);
        if (parsed != null) widget.onChanged(parsed);
      },
    );
  }
}

class _VariableDropdown extends StatelessWidget {
  final String label;
  final List<BuilderVariable> variables;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _VariableDropdown({
    required this.label,
    required this.variables,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = variables.any((variable) => variable.id == value)
        ? value
        : null;
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: selected,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: variables
          .map(
            (variable) => DropdownMenuItem(
              value: variable.id,
              child: Text('${variable.name} (${variable.type})'),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
