import 'package:flutter/material.dart';
import '../../../config/data/local/app_data.dart';
import '../data/analytics_datasource.dart';
import '../model/analytics_model.dart';

class AnalyticsController {
  final BuildContext context;
  final VoidCallback reloadData;

  final _ds = AnalyticsDataSource();

  // ── State ──────────────────────────────────────────────────────────────────
  AnalyticsOverview?  overview;
  ProductivityData?   productivity;
  List<TrendPoint>    trends = [];

  bool isLoadingOverview     = false;
  bool isLoadingProductivity = false;
  bool isLoadingTrends       = false;

  String overviewError     = '';
  String productivityError = '';

  // true when backend returns 403 plan-gate for productivity scores
  bool needsUpgradeForScores = false;

  int trendDays = 14;

  AnalyticsController({required this.context, required this.reloadData});

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> init() => loadAll();

  Future<void> loadAll() async {
    await Future.wait([loadOverview(), loadProductivity(), loadTrends()]);
  }

  // ── Data loaders ──────────────────────────────────────────────────────────

  Future<void> loadOverview() async {
    isLoadingOverview = true;
    overviewError     = '';
    reloadData();
    try {
      overview = await _ds.getOverview(AppData().getAccessToken() ?? '');
    } catch (e) {
      overviewError = e.toString();
      debugPrint('analytics/overview: $e');
    } finally {
      isLoadingOverview = false;
      reloadData();
    }
  }

  Future<void> loadProductivity({String? from, String? to}) async {
    isLoadingProductivity     = true;
    productivityError         = '';
    needsUpgradeForScores     = false;
    reloadData();
    try {
      productivity = await _ds.getProductivity(
        AppData().getAccessToken() ?? '',
        from: from, to: to,
      );
    } on PlanUpgradeRequired {
      needsUpgradeForScores = true;
    } catch (e) {
      productivityError = e.toString();
      debugPrint('analytics/productivity: $e');
    } finally {
      isLoadingProductivity = false;
      reloadData();
    }
  }

  Future<void> loadTrends({int? days}) async {
    isLoadingTrends = true;
    if (days != null) trendDays = days;
    reloadData();
    try {
      trends = await _ds.getTrends(
        AppData().getAccessToken() ?? '',
        days: trendDays,
      );
    } catch (e) {
      debugPrint('analytics/trends: $e');
    } finally {
      isLoadingTrends = false;
      reloadData();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  List<EmployeeScore> get topScorers =>
      (productivity?.scores ?? []).take(5).toList();

  void dispose() {}
}
