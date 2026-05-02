import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_widgets.dart';
import 'admin_screen.dart';

class AdminTodaySection extends StatefulWidget {
  const AdminTodaySection({super.key});
  @override
  State<AdminTodaySection> createState() => _AdminTodaySectionState();
}

class _AdminTodaySectionState extends State<AdminTodaySection> {
  List<dynamic> _records = [];
  bool _loading = true;
  String? _error;
  DateTime _date = DateTime.now();
  String _deptFilter = '';
  List<String> _departments = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final auth    = context.read<AuthService>();
      final dateStr = DateFormat('yyyy-MM-dd').format(_date);
      final list    = await ApiService(sessionCookie: auth.sessionCookie)
          .getAdminAttendance(date: dateStr);
      if (mounted) {
        final depts = list
            .map((r) => r['department'] as String? ?? '')
            .toSet()
            .where((d) => d.isNotEmpty)
            .toList()
          ..sort();
        setState(() {
          _records     = list;
          _departments = depts;
          _loading     = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<dynamic> get _filtered => _deptFilter.isEmpty
      ? _records
      : _records.where((r) => r['department'] == _deptFilter).toList();

  @override
  Widget build(BuildContext context) {
    return SectionPage(
      title: "Today's Attendance",
      child: Column(children: [
        // Filter bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(children: [
            // Date picker
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.calendar_today, size: 14,
                      color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(DateFormat('dd/MM/yyyy').format(_date),
                      style: const TextStyle(fontSize: 13)),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            // Dept filter
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _deptFilter.isEmpty ? null : _deptFilter,
                decoration: const InputDecoration(
                  hintText: 'All Departments',
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(value: null,
                      child: Text('All Departments')),
                  ..._departments.map((d) => DropdownMenuItem(
                      value: d, child: Text(d, overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (v) => setState(() => _deptFilter = v ?? ''),
              ),
            ),
          ]),
        ),
        const Divider(height: 1),

        // Summary row
        if (!_loading && _error == null)
          _SummaryRow(records: _filtered),

        // Table
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
                      ? const Center(
                          child: Text('No attendance records for this date.',
                              style: TextStyle(color: AppColors.textSecondary)))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: _AttendanceTable(records: _filtered),
                        ),
        ),
      ]),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = picked);
      _load();
    }
  }
}

class _SummaryRow extends StatelessWidget {
  final List<dynamic> records;
  const _SummaryRow({required this.records});

  @override
  Widget build(BuildContext context) {
    int present = 0, halfDay = 0, absent = 0;
    for (final r in records) {
      switch (r['status'] as String? ?? '') {
        case 'present':  present++;  break;
        case 'half_day': halfDay++;  break;
        default:         absent++;
      }
    }
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Expanded(child: _chip('Present', present, AppColors.success)),
        Expanded(child: _chip('Half Day', halfDay, AppColors.warning)),
        Expanded(child: _chip('Absent', absent, AppColors.error)),
        Expanded(child: _chip('Total', records.length, AppColors.primary)),
      ]),
    );
  }

  Widget _chip(String label, int count, Color color) => Column(children: [
    Text('$count', style: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w900, color: color)),
    Text(label, style: const TextStyle(
        fontSize: 11, color: AppColors.textSecondary)),
  ]);
}

class _AttendanceTable extends StatelessWidget {
  final List<dynamic> records;
  const _AttendanceTable({required this.records});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        // Header
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(children: [
            _TH('#', flex: 1),
            _TH('NAME & ID', flex: 3),
            _TH('DEPARTMENT', flex: 3),
            _TH('CHECK IN', flex: 2),
            _TH('CHECK OUT', flex: 2),
            _TH('HOURS', flex: 2),
            _TH('STATUS', flex: 2),
          ]),
        ),
        const SizedBox(height: 4),
        ...records.asMap().entries.map((e) => _Row(
            index: e.key + 1, record: e.value)),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(text, style: const TextStyle(
          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    ),
  );
}

class _Row extends StatelessWidget {
  final int index;
  final Map<String, dynamic> record;
  const _Row({required this.index, required this.record});

  @override
  Widget build(BuildContext context) {
    final status = record['status'] as String? ?? 'absent';
    Color color;
    switch (status) {
      case 'present':  color = AppColors.success; break;
      case 'half_day': color = AppColors.warning; break;
      default:         color = AppColors.error;
    }
    final ci  = record['check_in_time']  as String?;
    final co  = record['check_out_time'] as String?;
    final hrs = (record['working_hours'] as num?)?.toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(children: [
        _TD('$index', flex: 1,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        Expanded(flex: 3, child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(record['name'] as String? ?? '—',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            Text(record['employee_id'] as String? ?? '',
                style: const TextStyle(color: AppColors.accent,
                    fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        )),
        _TD(record['department'] as String? ?? '—', flex: 3,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        _TD(ci != null ? _fmt(ci) : '—', flex: 2,
            style: const TextStyle(fontSize: 12, color: AppColors.success,
                fontWeight: FontWeight.w600)),
        _TD(co != null ? _fmt(co) : '—', flex: 2,
            style: TextStyle(fontSize: 12,
                color: co != null ? const Color(0xFF7C3AED) : AppColors.textSecondary,
                fontWeight: FontWeight.w600)),
        _TD(hrs != null ? '${hrs.toStringAsFixed(1)}h' : '—', flex: 2,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        Expanded(flex: 2, child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: StatusBadge(status: status),
        )),
      ]),
    );
  }

  String _fmt(String t) => t.length >= 5 ? t.substring(0, 5) : t;
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(text, style: style ??
          const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
    ),
  );
}
