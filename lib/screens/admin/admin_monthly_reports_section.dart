import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_widgets.dart';
import 'admin_screen.dart';

class AdminMonthlyReportsSection extends StatefulWidget {
  const AdminMonthlyReportsSection({super.key});
  @override
  State<AdminMonthlyReportsSection> createState() =>
      _AdminMonthlyReportsSectionState();
}

class _AdminMonthlyReportsSectionState
    extends State<AdminMonthlyReportsSection> {
  DateTime _focused = DateTime.now();
  List<dynamic> _report = [];
  bool _loading = true;
  String? _error;
  String _deptFilter = '';
  List<String> _departments = [];

  @override
  void initState() { super.initState(); _load(); }

  String get _monthStr => DateFormat('yyyy-MM').format(_focused);

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final auth = context.read<AuthService>();
      final list = await ApiService(sessionCookie: auth.sessionCookie)
          .getAdminMonthlyReport(month: _monthStr);
      if (mounted) {
        final depts = list
            .map((r) => r['department'] as String? ?? '')
            .toSet()
            .where((d) => d.isNotEmpty)
            .toList()
          ..sort();
        setState(() {
          _report      = list;
          _departments = depts;
          _loading     = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<dynamic> get _filtered => _deptFilter.isEmpty
      ? _report
      : _report.where((r) => r['department'] == _deptFilter).toList();

  @override
  Widget build(BuildContext context) {
    return SectionPage(
      title: 'Monthly Reports',
      child: Column(children: [
        // Filter bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(children: [
            // Month picker
            GestureDetector(
              onTap: _pickMonth,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(DateFormat('MMMM yyyy').format(_focused),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _deptFilter.isEmpty ? null : _deptFilter,
                decoration: const InputDecoration(
                  hintText: 'All Departments',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                items: [
                  const DropdownMenuItem(value: null,
                      child: Text('All Departments')),
                  ..._departments.map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(d, overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (v) => setState(() => _deptFilter = v ?? ''),
              ),
            ),
          ]),
        ),
        const Divider(height: 1),

        // Table header
        if (!_loading && _error == null && _filtered.isNotEmpty)
          _TableHeader(),

        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        ErrorBox(message: _error!),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _load,
                            child: const Text('Retry')),
                      ])))
                  : _filtered.isEmpty
                      ? const Center(child: Text(
                          'No data for this month.',
                          style: TextStyle(color: AppColors.textSecondary)))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => _ReportRow(
                                data: _filtered[i], index: i + 1),
                          ),
                        ),
        ),
      ]),
    );
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Select Month'),
        content: SizedBox(
          width: 300,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, childAspectRatio: 2,
            ),
            itemCount: 12,
            itemBuilder: (_, i) {
              final m = DateTime(now.year, i + 1);
              final isSelected = m.month == _focused.month &&
                  m.year == _focused.year;
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _focused = m);
                  _load();
                },
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: isSelected
                            ? AppColors.primary : AppColors.divider),
                  ),
                  child: Center(child: Text(
                    DateFormat('MMM').format(m),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w700 : FontWeight.normal,
                    ),
                  )),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: const Row(children: [
        _TH('#', flex: 1),
        _TH('NAME', flex: 3),
        _TH('EMP. ID', flex: 2),
        _TH('DEPARTMENT', flex: 4),
        _TH('WORK DAYS', flex: 2),
        _TH('PRESENT', flex: 2),
        _TH('ABSENT', flex: 2),
        _TH('HALF DAY', flex: 2),
        _TH('AVG HRS', flex: 2),
        _TH('ATTEND %', flex: 2),
      ]),
    );
  }
}

class _TH extends StatelessWidget {
  final String text;
  final int flex;
  const _TH(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Text(text, style: const TextStyle(
          color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
    ),
  );
}

class _ReportRow extends StatelessWidget {
  final dynamic data;
  final int index;
  const _ReportRow({required this.data, required this.index});

  @override
  Widget build(BuildContext context) {
    final present  = (data['present']      as num?)?.toInt() ?? 0;
    final absent   = (data['absent']       as num?)?.toInt() ?? 0;
    final halfDay  = (data['half_day']     as num?)?.toInt() ?? 0;
    final wdays    = (data['working_days'] as num?)?.toInt() ?? 0;
    final avgHrs   = (data['avgHours']     as num?)?.toDouble()
                  ?? (data['avg_working_hours'] as num?)?.toDouble()
                  ?? 0.0;
    final double pct = wdays > 0
        ? ((present + halfDay * 0.5) / wdays * 100).clamp(0, 100)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.grey.shade50 : Colors.white,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(children: [
        _TD('$index', flex: 1,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12)),
        Expanded(flex: 3, child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(data['name'] as String? ?? '—',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 12)),
        )),
        _TD(data['employeeId'] as String? ?? '—', flex: 2,
            style: const TextStyle(
                color: AppColors.accent, fontSize: 11,
                fontWeight: FontWeight.w600)),
        _TD(data['department'] as String? ?? '—', flex: 4,
            style: const TextStyle(fontSize: 11,
                color: AppColors.textSecondary)),
        _TD('$wdays', flex: 2),
        _colorNum(present, AppColors.success, flex: 2),
        _colorNum(absent, AppColors.error, flex: 2),
        _colorNum(halfDay, AppColors.warning, flex: 2),
        _TD('${avgHrs.toStringAsFixed(1)}h', flex: 2),
        Expanded(flex: 2, child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text('${pct.toStringAsFixed(0)}%',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800,
                  color: pct >= 75 ? AppColors.success : AppColors.error)),
        )),
      ]),
    );
  }

  Widget _colorNum(int val, Color color, {required int flex}) =>
      Expanded(flex: flex, child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$val',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w800, color: color)),
        ),
      ));
}

class _TD extends StatelessWidget {
  final String text;
  final int flex;
  final TextStyle? style;
  const _TD(this.text, {required this.flex, this.style});

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(text, style: style ??
          const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
    ),
  );
}
