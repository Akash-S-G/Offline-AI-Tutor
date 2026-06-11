import 'package:flutter/material.dart';
import '../controllers/experiment_builder_controller.dart';
import '../models/builder_rule.dart';
import 'builder_search_bar.dart';
import 'empty_state_card.dart';
import 'rule_runtime_config_editors.dart';
import '../wizards/rule_wizard_dialog.dart';

class RuleEditor extends StatefulWidget {
  final ExperimentBuilderController controller;

  const RuleEditor({super.key, required this.controller});

  @override
  State<RuleEditor> createState() => _RuleEditorState();
}

class _RuleEditorState extends State<RuleEditor> {
  String _query = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final rules = BuilderSearchBar.filter(
          widget.controller.state.rules,
          _query,
          (rule) => [rule.name, rule.id, rule.trigger, rule.type],
        );
        final compact = MediaQuery.sizeOf(context).width < 380;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Interactions (${widget.controller.state.rules.length})',
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
                    label: Text(compact ? 'Add' : 'Add Interaction'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final newRule = await showDialog<BuilderRule>(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => RuleWizardDialog(
                          availableVariables: widget.controller.state.variables,
                          availableObjects: widget.controller.state.objects,
                        ),
                      );

                      if (newRule != null) {
                        widget.controller.addRule(newRule);
                      }
                    },
                  ),
                ],
              ),
            ),
            BuilderSearchBar(
              hintText: 'Search Interactions',
              onChanged: (value) => setState(() => _query = value),
            ),
            const Divider(height: 1),
            Expanded(
              child: widget.controller.state.rules.isEmpty
                  ? _buildEmptyState(context)
                  : rules.isEmpty
                  ? const Center(child: Text('No matching interactions'))
                  : ListView.builder(
                      key: const PageStorageKey<String>('builder_rules_list'),
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      primary: false,
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

  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateCard(
      icon: Icons.account_tree_rounded,
      title: 'No Interactions Yet',
      message: 'Interactions define cause and effect in your experiment.',
      primaryLabel: 'Create Interaction',
      onPrimary: () async {
        final newRule = await showDialog<BuilderRule>(
          context: context,
          barrierDismissible: false,
          builder: (context) => RuleWizardDialog(
            availableVariables: widget.controller.state.variables,
            availableObjects: widget.controller.state.objects,
          ),
        );
        if (newRule != null && mounted) widget.controller.addRule(newRule);
      },
    );
  }

  Widget _buildRuleCard(BuildContext context, BuilderRule rule) {
    final conditionVar = rule.condition['variableId'] ?? 'Unknown';
    final conditionOp = rule.condition['operator'] ?? '==';
    final conditionVal = rule.condition['value'] ?? 'Unknown';
    final trigger = rule.trigger;

    final actions = _actionsFor(rule);

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
                      widget.controller.deleteRule(rule.id);
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
                      width: 84,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          trigger,
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
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
                        actions
                            .map(
                              (action) =>
                                  action['type']?.toString() ?? 'action',
                            )
                            .join('\n'),
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
          'ID: ${rule.id}\nTrigger: ${rule.trigger}\nCondition: ${rule.condition}\nActions: ${rule.actions}\nRuntime Config: ${rule.runtimeConfig}\nDescription: ${rule.description}',
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
    var trigger = rule.trigger;
    var condition = Map<String, dynamic>.from(rule.condition);
    var actions = _actionsFor(rule);

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
                const SizedBox(height: 12),
                RuleTriggerDropdown(
                  trigger: trigger,
                  onChanged: (next) => setDialogState(() => trigger = next),
                ),
                const SizedBox(height: 12),
                ConditionBuilderEditor(
                  variables: widget.controller.state.variables,
                  condition: condition,
                  onChanged: (next) => setDialogState(() => condition = next),
                ),
                const SizedBox(height: 16),
                ActionBuilderEditor(
                  variables: widget.controller.state.variables,
                  objects: widget.controller.state.objects,
                  actions: actions,
                  onChanged: (next) => setDialogState(() => actions = next),
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
              onPressed: () {
                widget.controller.editRule(
                  rule.copyWith(
                    name: nameController.text.trim(),
                    trigger: trigger,
                    condition: condition,
                    actions: actions,
                    runtimeConfig: {
                      'trigger': trigger,
                      'condition': condition,
                      'actions': actions,
                    },
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

  List<Map<String, dynamic>> _actionsFor(BuilderRule rule) {
    return rule.actions;
  }
}
