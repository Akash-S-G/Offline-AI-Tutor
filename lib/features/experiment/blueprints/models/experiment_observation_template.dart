class ExperimentObservationTemplate {
  final List<String> columns;
  final int requiredRows;
  final bool autoRecord;

  const ExperimentObservationTemplate({
    this.columns = const [],
    this.requiredRows = 1,
    this.autoRecord = false,
  });

  factory ExperimentObservationTemplate.fromJson(Map<String, dynamic> json) {
    return ExperimentObservationTemplate(
      columns: (json['columns'] as List<dynamic>? ?? const [])
          .map((column) => column.toString())
          .toList(growable: false),
      requiredRows: json['requiredRows'] is num
          ? (json['requiredRows'] as num).toInt()
          : 1,
      autoRecord: json['autoRecord'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'columns': columns,
      'requiredRows': requiredRows,
      'autoRecord': autoRecord,
    };
  }
}
