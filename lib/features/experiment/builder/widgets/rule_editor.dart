import 'package:flutter/material.dart';
import '../controllers/experiment_builder_controller.dart';
import '../models/builder_rule.dart';
import '../models/builder_variable.dart';
import '../wizards/rule_wizard_dialog.dart';

class RuleEditor extends StatelessWidget {
  final ExperimentBuilderController controller;

  const RuleEditor({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final rules = controller.state.rules;
        final compact = MediaQuery.sizeOf(context).width < 380;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Logic & Rules',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(compact ? 'Add' : 'Add Rule'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final newRule = await showDialog<BuilderRule>(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => RuleWizardDialog(
                          availableVariables: controller.state.variables,
                        ),
                      );

                      if (newRule != null) {
                        controller.addRule(newRule);
                      }
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: rules.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      primary: true,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: rules.length,
                      itemBuilder: (context, index) {
                        final r = rules[index];
                        return _buildRuleCard(context, r);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.account_tree_rounded,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Create your first rule',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Rules define the interactive logic of your experiment.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Example:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'IF Temperature > 100\nTHEN Start Boiling Animation',
                  style: TextStyle(color: Color(0xFF1E293B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleCard(BuildContext context, BuilderRule rule) {
    final conditionVar = rule.condition['variableId'] ?? 'Unknown';
    final conditionOp = rule.condition['operator'] ?? '==';
    final conditionVal = rule.condition['value'] ?? 'Unknown';

    final actionType = rule.action['type'] ?? 'Unknown Action';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.psychology_rounded,
                        color: Color(0xFF3B82F6),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rule.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'view') {
                      _showRuleDetails(context, rule);
                    } else if (action == 'edit') {
                      _showEditRuleDialog(context, rule);
                    } else if (action == 'delete') {
                      controller.deleteRule(rule.id);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'view', child: Text('View')),
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Text(
                          'IF',
                          style: TextStyle(
                            color: Color(0xFFD97706),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$conditionVar $conditionOp $conditionVal',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Text(
                          'THEN',
                          style: TextStyle(
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        actionType.toString().toUpperCase().replaceAll(
                          '_',
                          ' ',
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRuleDetails(BuildContext context, BuilderRule rule) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(rule.name),
        content: SelectableText(
          'ID: ${rule.id}\nCondition: ${rule.condition}\nAction: ${rule.action}\nDescription: ${rule.description}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditRuleDialog(BuildContext context, BuilderRule rule) {
    final nameController = TextEditingController(text: rule.name);
    final thresholdController = TextEditingController(
      text: '${rule.condition['value'] ?? ''}',
    );
    var operator = rule.condition['operator']?.toString() ?? '>';
    var action = rule.action['type']?.toString() ?? 'show_warning';
    BuilderVariable? selectedVariable;
    final variableId = rule.condition['variableId']?.toString();
    for (final variable in controller.state.variables) {
      if (variable.id == variableId) {
        selectedVariable = variable;
        break;
      }
    }

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Rule'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                DropdownButtonFormField<BuilderVariable>(
                  isExpanded: true,
                  initialValue: selectedVariable,
                  decoration: const InputDecoration(labelText: 'Variable'),
                  items: controller.state.variables
                      .map(
                        (variable) => DropdownMenuItem(
                          value: variable,
                          child: Text('${variable.name} (${variable.id})'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedVariable = value),
                ),
                DropdownButtonFormField<String>(
                  initialValue: operator,
                  decoration: const InputDecoration(labelText: 'Operator'),
                  items: const [
                    DropdownMenuItem(value: '>', child: Text('>')),
                    DropdownMenuItem(value: '<', child: Text('<')),
                    DropdownMenuItem(value: '>=', child: Text('>=')),
                    DropdownMenuItem(value: '<=', child: Text('<=')),
                    DropdownMenuItem(value: '==', child: Text('==')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => operator = value ?? operator),
                ),
                TextField(
                  controller: thresholdController,
                  decoration: const InputDecoration(labelText: 'Threshold'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  initialValue: action,
                  decoration: const InputDecoration(labelText: 'Action'),
                  items: const [
                    DropdownMenuItem(
                      value: 'show_warning',
                      child: Text('Show Warning'),
                    ),
                    DropdownMenuItem(
                      value: 'hide_object',
                      child: Text('Hide Object'),
                    ),
                    DropdownMenuItem(
                      value: 'start_recording',
                      child: Text('Start Recording'),
                    ),
                    DropdownMenuItem(
                      value: 'stop_recording',
                      child: Text('Stop Recording'),
                    ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => action = value ?? action),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedVariable == null
                  ? null
                  : () {
                      controller.editRule(
                        rule.copyWith(
                          name: nameController.text.trim(),
                          condition: {
                            'variableId': selectedVariable!.id,
                            'operator': operator,
                            'value':
                                num.tryParse(thresholdController.text) ?? 0,
                          },
                          action: {'type': action},
                        ),
                      );
                      Navigator.pop(context);
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
