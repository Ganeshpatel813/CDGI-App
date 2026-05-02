import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../models/attendance.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_widgets.dart';
import 'admin_screen.dart';

class AdminDashboardSection extends StatefulWidget {
  const AdminDashboardSection({super.key});
  @override
  State<AdminDashboardSection> createState() => _AdminDashboardSectionState();
}

class _AdminDashboardSectionState extends State<AdminDashboardSection> {
  AdminStats? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final auth = context.read<AuthService>();
      final s    = await ApiService(sessionCookie: auth.sessionCookie).getAdminStats();
      if (mounted) setState(() { _stats = s; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionPage(
      title: 'Dashboard',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorRetry(error: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // 5 stat cards
                      _StatsGrid(stats: _stats!),
                      const SizedBox(height: 20),
                      // Department breakdown
                      if (_stats!.departments.isNotEmpty) ...[
                        const Text('Department Breakdown',
                            style: TextStyle(fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 10),
                        ..._stats!.departments.map((d) => _DeptBar(dept: d)),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final AdminStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Expanded(child: StatCard(label: 'Total Faculty',
            value: '${stats.totalFaculty}',
            color: AppColors.primary, icon: Icons.people)),
        Expanded(child: StatCard(label: 'Present Today',
            value: '${stats.todayPresent}',
            color: AppColors.success, icon: Icons.check_circle_outline)),
        Expanded(child: StatCard(label: 'Absent Today',
            value: '${stats.todayAbsent}',
            color: AppColors.error, icon: Icons.cancel_outlined)),
      ]),
      Row(children: [
        Expanded(child: StatCard(label: 'Checked Out',
            value: '${stats.todayCheckout}',
            color: AppColors.warning, icon: Icons.logout)),
        Expanded(child: StatCard(label: 'Half Day',
            value: '${stats.todayHalfDay}',
            color: AppColors.accent, icon: Icons.timelapse)),
        Expanded(child: StatCard(label: 'Total Records',
            value: '${stats.totalAttendance}',
            color: AppColors.info, icon: Icons.bar_chart)),
      ]),
    ]);
  }
}

class _DeptBar extends StatelessWidget {
  final Map<String, dynamic> dept;
  const _DeptBar({required this.dept});

  @override
  Widget build(BuildContext context) {
    final total   = (dept['total']   as num?)?.toInt() ?? 0;
    final present = (dept['present'] as num?)?.toInt() ?? 0;
    final pct     = total > 0 ? present / total : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(dept['department'] as String? ?? '—',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
            Text('$present / $total present',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct, minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                  pct >= 0.75 ? AppColors.success : AppColors.warning),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ErrorBox(message: error),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
      ]),
    ),
  );
}
