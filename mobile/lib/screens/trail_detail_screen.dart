import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/condition_report.dart';
import '../models/trail_detail.dart';
import '../services/report_api.dart';
import '../services/trail_api.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/trail_detail_view_model.dart';
import 'login_screen.dart';
import 'report_screen.dart';

/// A trail's detail page: the register's facts, its current conditions and
/// recent reports, and the button to report its condition.
class TrailDetailScreen extends StatelessWidget {
  const TrailDetailScreen({
    super.key,
    required this.trailId,
    required this.trailName,
    this.api,
    this.reportApi,
  });

  final int trailId;

  /// Shown while the details load.
  final String trailName;
  final TrailApi? api;
  final ReportApi? reportApi;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          TrailDetailViewModel(api: api ?? TrailApi(), trailId: trailId)
            ..load(),
      child: _TrailDetailView(
        trailId: trailId,
        trailName: trailName,
        reportApi: reportApi,
      ),
    );
  }
}

class _TrailDetailView extends StatelessWidget {
  const _TrailDetailView({
    required this.trailId,
    required this.trailName,
    this.reportApi,
  });

  final int trailId;
  final String trailName;
  final ReportApi? reportApi;

  @override
  Widget build(BuildContext context) {
    final model = context.watch<TrailDetailViewModel>();
    final detail = model.detail;
    return Scaffold(
      appBar: AppBar(title: Text(detail?.name ?? trailName)),
      body: switch ((detail, model.error)) {
        (final TrailDetail d, _) => RefreshIndicator(
          onRefresh: model.load,
          child: _DetailBody(detail: d),
        ),
        (null, final String error) => _LoadError(
          message: error,
          onRetry: model.notFound ? null : model.load,
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
      bottomNavigationBar: model.notFound
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton.icon(
                  onPressed: () => _reportCondition(context),
                  icon: const Icon(Icons.add_comment_outlined),
                  label: const Text('Report condition'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _reportCondition(BuildContext context) async {
    if (!context.read<AuthViewModel>().isLoggedIn) {
      await showModalBottomSheet<void>(
        context: context,
        builder: (sheet) => const _LogInToReport(),
      );
      return;
    }
    final model = context.read<TrailDetailViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final report = await Navigator.of(context).push<ConditionReport>(
      MaterialPageRoute(
        builder: (_) => ReportScreen(
          trailId: trailId,
          trailName: model.detail?.name ?? trailName,
          api: reportApi,
        ),
      ),
    );
    if (report == null) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Thanks, report submitted')),
    );
    await model.load();
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail});

  final TrailDetail detail;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();
    final length = detail.lengthKm;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _Fact(
              label: 'Length',
              value: length == null ? '-' : '${length.toStringAsFixed(1)} km',
            ),
            const SizedBox(width: 8),
            _Fact(label: 'Difficulty', value: detail.difficulty.label),
            const SizedBox(width: 8),
            _Fact(label: 'Time', value: detail.timeToComplete ?? '-'),
          ],
        ),
        const SizedBox(height: 20),
        Text('Current conditions', style: text.titleSmall),
        const SizedBox(height: 8),
        if (detail.currentConditions.isEmpty)
          Text('No recent reports', style: text.bodyMedium)
        else
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final report in detail.currentConditions)
                Chip(
                  label: Text(
                    '${report.summary} | ${timeAgo(report.reportedAt, now)}',
                  ),
                ),
            ],
          ),
        if (detail.recentReports.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Recent reports', style: text.titleSmall),
          for (final report in detail.recentReports)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(report.summary),
              subtitle: Text(
                [
                  if (report.note != null) report.note!,
                  timeAgo(report.reportedAt, now),
                ].join('\n'),
              ),
            ),
        ],
        if (detail.description != null) ...[
          const SizedBox(height: 20),
          Text('About', style: text.titleSmall),
          const SizedBox(height: 4),
          Text(detail.description!, style: text.bodyMedium),
        ],
        if (detail.website != null) ...[
          const SizedBox(height: 20),
          Text('Website', style: text.titleSmall),
          const SizedBox(height: 4),
          SelectableText(detail.website!, style: text.bodySmall),
        ],
      ],
    );
  }
}

/// One of the three facts at the top of the page, such as the length.
class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Card.outlined(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Column(
            children: [
              Text(label, style: text.labelSmall),
              const SizedBox(height: 2),
              Text(
                value,
                style: text.titleSmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;

  /// Null when retrying cannot help, such as for a trail that no longer exists.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shown instead of the report form to guests.
class _LogInToReport extends StatelessWidget {
  const _LogInToReport();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Log in to report conditions', style: text.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Reports come from logged-in walkers, so others can trust them. '
              'You can still read every report without an account.',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                navigator.push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('Log in'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Not now'),
            ),
          ],
        ),
      ),
    );
  }
}
