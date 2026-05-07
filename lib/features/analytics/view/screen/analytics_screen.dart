import 'package:flutter/material.dart';
import '../../controller/analytics_controller.dart';
import '../widgets/score_card.dart';
import '../widgets/trend_chart.dart';
import '../../../billing/view/screen/billing_screen.dart';
import '../../../../config/theme/app_pallete.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late final AnalyticsController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnalyticsController(
      context: context,
      reloadData: () {
        if (mounted) setState(() {});
      },
    );
    _ctrl.init();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: cs.onSurface,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Analytics',
          style: textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.refresh_rounded,
                size: 20,
                color: cs.onSurface,
              ),
            ),
            onPressed: _ctrl.loadAll,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: cs.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _ctrl.loadAll,
        color: Pallete.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel("TODAY'S SNAPSHOT"),
              const SizedBox(height: 12),
              _buildOverview(context),
              const SizedBox(height: 28),
              _SectionLabel('14-DAY TRENDS'),
              const SizedBox(height: 12),
              _buildTrends(context),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SectionLabel('PRODUCTIVITY SCORES'),
                  if (_ctrl.productivity != null)
                    _ScoreBadge(avg: _ctrl.productivity!.summary.avgScore),
                ],
              ),
              const SizedBox(height: 12),
              _buildProductivity(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section builders ──────────────────────────────────────────────────────

  Widget _buildOverview(BuildContext context) {
    if (_ctrl.isLoadingOverview && _ctrl.overview == null) {
      return _Loader();
    }
    final ov = _ctrl.overview;
    if (ov == null) return _ErrorCard(message: _ctrl.overviewError);

    return Column(
      children: [
        Row(children: [
          Expanded(
            child: _StatCard(
              label: 'Online Now',
              value: '${ov.onlineNow}',
              sub: 'of ${ov.totalEmployees} employees',
              color: Pallete.successColor,
              icon: Icons.wifi_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'Attendance',
              value: '${ov.attendanceRate}%',
              sub: '${ov.attendanceToday} present today',
              color: Pallete.infoColor,
              icon: Icons.how_to_reg_rounded,
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: _StatCard(
              label: 'Tasks Today',
              value: '${ov.tasksToday}',
              sub: '${ov.taskBreakdown.completed} completed',
              color: Pallete.primaryColor,
              icon: Icons.task_alt_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'Overdue',
              value: '${ov.overdueTasks}',
              sub: 'needs attention',
              color: ov.overdueTasks > 0 ? Pallete.errorColor : Pallete.successColor,
              icon: Icons.warning_amber_rounded,
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildTrends(BuildContext context) {
    if (_ctrl.isLoadingTrends && _ctrl.trends.isEmpty) {
      return _Loader(height: 180);
    }
    if (_ctrl.trends.isEmpty) return const _ErrorCard(message: 'No trend data');
    return TrendChart(trends: _ctrl.trends);
  }

  Widget _buildProductivity(BuildContext context) {
    if (_ctrl.needsUpgradeForScores) return const _UpgradeWall();
    if (_ctrl.isLoadingProductivity && _ctrl.productivity == null) {
      return _Loader(height: 300);
    }
    if (_ctrl.productivityError.isNotEmpty) {
      return _ErrorCard(message: _ctrl.productivityError);
    }
    final scores = _ctrl.productivity?.scores ?? [];
    if (scores.isEmpty) {
      return const _ErrorCard(message: 'No employee data for this period');
    }
    return Column(
      children: scores.asMap().entries
          .map((e) => ScoreCard(rank: e.key + 1, score: e.value))
          .toList(),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall!.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ─── Score badge ──────────────────────────────────────────────────────────────

class _ScoreBadge extends StatelessWidget {
  final int avg;
  const _ScoreBadge({required this.avg});

  @override
  Widget build(BuildContext context) {
    final color = avg >= 70
        ? Pallete.successColor
        : avg >= 50
        ? Pallete.infoColor
        : Pallete.errorColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        'Avg $avg/100',
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Loader ───────────────────────────────────────────────────────────────────

class _Loader extends StatelessWidget {
  final double height;
  const _Loader({this.height = 120});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: CircularProgressIndicator(color: Pallete.primaryColor),
      ),
    );
  }
}

// ─── Error card ───────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message.isEmpty ? 'Something went wrong' : message,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
          color: cs.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

// ─── Stat card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: textTheme.labelSmall!.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: textTheme.headlineMedium!.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: textTheme.labelSmall!.copyWith(
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Upgrade wall ─────────────────────────────────────────────────────────────

class _UpgradeWall extends StatelessWidget {
  const _UpgradeWall();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(
          color: Pallete.primaryColor.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Pallete.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              color: Pallete.primaryColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Productivity Scores require Pro',
            style: textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Weekly scores, A–D grades, and top performer rankings are available on Pro and above.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall!.copyWith(
              color: cs.onSurface.withValues(alpha: 0.55),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Pallete.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BillingScreen()),
              ),
              child: Text(
                'Upgrade to Pro →',
                style: textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}