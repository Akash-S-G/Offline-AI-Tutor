import 'package:flutter/material.dart';
import '../controllers/experiment_builder_controller.dart';
import '../models/builder_rule.dart';
import 'package:uuid/uuid.dart';
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Rule'),
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
                      padding: const EdgeInsets.all(16),
                      itemCount: rules.length,
                      itemBuilder: (context, index) {
                        final r = rules[index];
                        return _buildRuleCard(r);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_tree_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Create your first rule',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
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
                Text('Example:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                SizedBox(height: 4),
                Text('IF Temperature > 100\nTHEN Start Boiling Animation', style: TextStyle(color: Color(0xFF1E293B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleCard(BuilderRule rule) {
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
                      const Icon(Icons.psychology_rounded, color: Color(0xFF3B82F6), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rule.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => controller.deleteRule(rule.id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
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
                        child: Text('IF', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$conditionVar $conditionOp $conditionVal',
                        style: const TextStyle(fontSize: 16, color: Color(0xFF1E293B), fontFamily: 'monospace'),
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
                        child: Text('THEN', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        actionType.toString().toUpperCase().replaceAll('_', ' '),
                        style: const TextStyle(fontSize: 16, color: Color(0xFF1E293B)),
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
}
