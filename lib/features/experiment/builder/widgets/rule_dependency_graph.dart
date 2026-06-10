import 'package:flutter/material.dart';

import '../models/builder_rule.dart';
import '../models/builder_variable.dart';

class RuleDependencyGraphRow {
  final String variable;
  final String rule;
  final String action;

  const RuleDependencyGraphRow({
    required this.variable,
    required this.rule,
    required this.action,
  });
}

class RuleDependencyGraph extends StatelessWidget {
  final List<BuilderVariable> variables;
  final List<BuilderRule> rules;

  const RuleDependencyGraph({
    super.key,
    required this.variables,
    required this.rules,
  });

  static List<RuleDependencyGraphRow> buildRows({
    required List<BuilderVariable> variables,
    required List<BuilderRule> rules,
  }) {
    final variableNames = {
      for (final variable in variables) variable.id: variable.name,
    };
    return rules
        .expand((rule) {
          final variableId = rule.condition['variableId']?.toString() ?? '';
          final variableName = variableNames[variableId] ?? variableId;
          return rule.actions.map((action) {
            final type = action['type']?.toString() ?? 'action';
            final target =
                action['objectId']?.toString() ??
                action['variableId']?.toString() ??
                action['targetVariable']?.toString() ??
                action['message']?.toString() ??
                '';
            return RuleDependencyGraphRow(
              variable: variableName,
              rule: rule.name,
              action: target.isEmpty ? type : '$type -> $target',
            );
          });
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final rows = buildRows(variables: variables, rules: rules);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rule Dependency Graph',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          const Text(
            'No rule dependencies',
            style: TextStyle(color: Colors.grey),
          )
        else
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${row.variable}\n  ↓\n${row.rule}\n  ↓\n${row.action}',
              ),
            ),
          ),
      ],
    );
  }
}
