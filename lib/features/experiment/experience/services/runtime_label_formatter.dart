class RuntimeLabelFormatter {
  const RuntimeLabelFormatter();

  String format(String value) {
    var label = value.trim();
    for (final prefix in ['var_', 'obj_', 'rule_']) {
      if (label.startsWith(prefix)) label = label.substring(prefix.length);
    }
    label = label.replaceAll(RegExp(r'[_-]+'), ' ');
    if (label.isEmpty) return 'Item';
    return label
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}
