import 'package:flutter/material.dart';

import '../models/builder_variable.dart';

typedef RuntimeConfigChanged = void Function(Map<String, dynamic> config);

class NumericDisplayConfigEditor extends StatelessWidget {
  final Map<String, dynamic> config;
  final RuntimeConfigChanged onChanged;

  const NumericDisplayConfigEditor({
    super.key,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _ConfigSection(
      title: 'Numeric Display',
      children: [
        _TextConfigField(
          label: 'Label',
          value: config['label']?.toString() ?? '',
          onChanged: (value) => _set('label', value),
        ),
        _TextConfigField(
          label: 'Unit',
          value: config['unit']?.toString() ?? '',
          onChanged: (value) => _set('unit', value),
        ),
        _NumberConfigField(
          label: 'Precision',
          value: config['precision'] ?? 1,
          onChanged: (value) => _set('precision', value.round()),
        ),
      ],
    );
  }

  void _set(String key, dynamic value) {
    onChanged({...config, key: value});
  }
}

class GaugeConfigEditor extends StatelessWidget {
  final Map<String, dynamic> config;
  final RuntimeConfigChanged onChanged;

  const GaugeConfigEditor({
    super.key,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _ConfigSection(
      title: 'Gauge',
      children: [
        _NumberConfigField(
          label: 'Min',
          value: config['min'] ?? 0,
          onChanged: (value) => _set('min', value),
        ),
        _NumberConfigField(
          label: 'Max',
          value: config['max'] ?? 100,
          onChanged: (value) => _set('max', value),
        ),
        _TextConfigField(
          label: 'Unit',
          value: config['unit']?.toString() ?? '',
          onChanged: (value) => _set('unit', value),
        ),
        _NumberConfigField(
          label: 'Warning Threshold',
          value: config['warningThreshold'] ?? 80,
          onChanged: (value) => _set('warningThreshold', value),
        ),
      ],
    );
  }

  void _set(String key, dynamic value) {
    onChanged({...config, key: value});
  }
}

class ProgressBarConfigEditor extends StatelessWidget {
  final Map<String, dynamic> config;
  final RuntimeConfigChanged onChanged;

  const ProgressBarConfigEditor({
    super.key,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _ConfigSection(
      title: 'Progress Bar',
      children: [
        _NumberConfigField(
          label: 'Min',
          value: config['min'] ?? 0,
          onChanged: (value) => _set('min', value),
        ),
        _NumberConfigField(
          label: 'Max',
          value: config['max'] ?? 100,
          onChanged: (value) => _set('max', value),
        ),
      ],
    );
  }

  void _set(String key, dynamic value) {
    onChanged({...config, key: value});
  }
}

class LineGraphConfigEditor extends StatelessWidget {
  final List<BuilderVariable> variables;
  final Map<String, dynamic> config;
  final RuntimeConfigChanged onChanged;

  const LineGraphConfigEditor({
    super.key,
    required this.variables,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _ConfigSection(
      title: 'Line Graph',
      children: [
        _VariableDropdown(
          label: 'Variable',
          variables: variables,
          value: config['variableId']?.toString(),
          onChanged: (value) => _set('variableId', value),
        ),
        _NumberConfigField(
          label: 'History Window',
          value: config['historyWindow'] ?? 100,
          onChanged: (value) => _set('historyWindow', value.round()),
        ),
        _TextConfigField(
          label: 'X Axis Label',
          value: config['xAxis']?.toString() ?? 'Time',
          onChanged: (value) => _set('xAxis', value),
        ),
        _TextConfigField(
          label: 'Y Axis Label',
          value: config['yAxis']?.toString() ?? '',
          onChanged: (value) => _set('yAxis', value),
        ),
      ],
    );
  }

  void _set(String key, dynamic value) {
    onChanged({...config, key: value});
  }
}

class ScatterPlotConfigEditor extends StatelessWidget {
  final List<BuilderVariable> variables;
  final Map<String, dynamic> config;
  final RuntimeConfigChanged onChanged;

  const ScatterPlotConfigEditor({
    super.key,
    required this.variables,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _ConfigSection(
      title: 'Scatter Plot',
      children: [
        _VariableDropdown(
          label: 'X Variable',
          variables: variables,
          value: config['xVariable']?.toString(),
          onChanged: (value) => _set('xVariable', value),
        ),
        _VariableDropdown(
          label: 'Y Variable',
          variables: variables,
          value: config['yVariable']?.toString(),
          onChanged: (value) => _set('yVariable', value),
        ),
      ],
    );
  }

  void _set(String key, dynamic value) {
    onChanged({...config, key: value});
  }
}

class TableConfigEditor extends StatelessWidget {
  final Map<String, dynamic> config;
  final RuntimeConfigChanged onChanged;

  const TableConfigEditor({
    super.key,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _ConfigSection(
      title: 'Table',
      children: [
        _NumberConfigField(
          label: 'Max Rows',
          value: config['maxRows'] ?? 100,
          onChanged: (value) => _set('maxRows', value.round()),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Auto Record'),
          value: config['autoRecord'] == true,
          onChanged: (value) => _set('autoRecord', value),
        ),
      ],
    );
  }

  void _set(String key, dynamic value) {
    onChanged({...config, key: value});
  }
}

class RuntimeObjectConfigEditor extends StatelessWidget {
  final String objectType;
  final List<BuilderVariable> variables;
  final Map<String, dynamic> config;
  final RuntimeConfigChanged onChanged;

  const RuntimeObjectConfigEditor({
    super.key,
    required this.objectType,
    required this.variables,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (objectType) {
      case 'numericDisplay':
        return NumericDisplayConfigEditor(config: config, onChanged: onChanged);
      case 'gauge':
        return GaugeConfigEditor(config: config, onChanged: onChanged);
      case 'progressBar':
        return ProgressBarConfigEditor(config: config, onChanged: onChanged);
      case 'lineGraph':
        return LineGraphConfigEditor(
          variables: variables,
          config: config,
          onChanged: onChanged,
        );
      case 'scatterPlot':
        return ScatterPlotConfigEditor(
          variables: variables,
          config: config,
          onChanged: onChanged,
        );
      case 'table':
        return TableConfigEditor(config: config, onChanged: onChanged);
      default:
        return const SizedBox.shrink();
    }
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

class _TextConfigField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _TextConfigField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_TextConfigField> createState() => _TextConfigFieldState();
}

class _TextConfigFieldState extends State<_TextConfigField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_TextConfigField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      _controller.text = widget.value;
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
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
      ),
      onChanged: widget.onChanged,
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
