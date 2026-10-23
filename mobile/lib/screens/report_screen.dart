import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/condition_report.dart';
import '../services/report_api.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/report_view_model.dart';
import 'login_screen.dart';

/// The report form: choose what was found, how bad it is, add an optional
/// note, and submit. Closes with the stored report once it is sent.
class ReportScreen extends StatelessWidget {
  const ReportScreen({
    super.key,
    required this.trailId,
    required this.trailName,
    this.api,
  });

  final int trailId;
  final String trailName;
  final ReportApi? api;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ReportViewModel(
        api: api ?? ReportApi(),
        auth: context.read<AuthViewModel>(),
        trailId: trailId,
      ),
      child: _ReportForm(trailName: trailName),
    );
  }
}

class _ReportForm extends StatefulWidget {
  const _ReportForm({required this.trailName});

  final String trailName;

  @override
  State<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<_ReportForm> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final report = await context.read<ReportViewModel>().submit(
      note: _note.text,
    );
    if (report != null && mounted) Navigator.of(context).pop(report);
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ReportViewModel>();
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Report condition'),
            Text(
              widget.trailName,
              style: text.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('What did you find?', style: text.titleSmall),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.15,
            children: [
              for (final type in ConditionType.values)
                _ConditionTile(
                  type: type,
                  selected: model.conditionType == type,
                  onTap: () => model.selectCondition(type),
                ),
            ],
          ),
          if (model.needsSeverity) ...[
            const SizedBox(height: 20),
            Text('How bad is it?', style: text.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<Severity>(
              segments: [
                for (final s in Severity.values)
                  ButtonSegment(value: s, label: Text(s.label)),
              ],
              selected: {model.severity},
              onSelectionChanged: (choice) =>
                  model.selectSeverity(choice.first),
            ),
          ],
          const SizedBox(height: 20),
          TextField(
            controller: _note,
            maxLength: 500,
            maxLines: 3,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'For example, deep mud by the footbridge',
            ),
          ),
        ],
      ),
      // Errors sit just above Submit, where the user is already looking.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (model.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    model.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (model.sessionExpired)
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: const Text('Log in'),
                ),
              FilledButton(
                onPressed: model.canSubmit ? _submit : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: model.busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A large tile for one condition type.
class _ConditionTile extends StatelessWidget {
  const _ConditionTile({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final ConditionType type;
  final bool selected;
  final VoidCallback onTap;

  static IconData _icon(ConditionType type) => switch (type) {
    ConditionType.clear => Icons.check_circle_outline,
    ConditionType.mud => Icons.landslide_outlined,
    ConditionType.flooding => Icons.flood_outlined,
    ConditionType.fallenTree => Icons.forest_outlined,
    ConditionType.stormDamage => Icons.thunderstorm_outlined,
    ConditionType.closure => Icons.block,
    ConditionType.forestryWork => Icons.agriculture_outlined,
    ConditionType.livestock => Icons.pets,
    ConditionType.other => Icons.more_horiz,
  };

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? colours.primaryContainer : colours.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? colours.primary : colours.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_icon(type), size: 28),
              const SizedBox(height: 6),
              Text(
                type.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
