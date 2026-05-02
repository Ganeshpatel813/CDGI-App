import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_widgets.dart';
import 'admin_screen.dart';

class AdminAttendanceRecordsSection extends StatefulWidget {
  const AdminAttendanceRecordsSection({super.key});
  @override
  State<AdminAttendanceRecordsSection> createState() =>
      _AdminAttendanceRecordsSectionState();
}

class _AdminAttendanceRecordsSectionState
    extends State<AdminAttendanceRecordsSection> {
  List<dynamic> _records = [];
  bool _loading = false;
  String? _error;
  DateTime _from = DateTime.now().subtract(const Duration(days: 7));
  DateTime _to   = DateTime.now();
  String _deptFilter = '';
  List<String> _departments = [];
  bool _searched = false;

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; _searched = true; });
    try {
      final auth    = context.read<AuthService>();
      final fromStr = DateFormat('yyyy-MM-dd').format(_from);
      final toStr   = DateFormat('yyyy-MM-dd').format(_to);
      final list    = await ApiService(sessionCookie: auth.sessionCookie)
          .getAdminAttendance(from: fromStr, to: toStr);
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
      title: 'Attendance Records',
      child: Column(children: [
        // Filter bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              Expanded(child: _DateField(
                label: 'Date From',
                date: _from,
                onPick: (d) => setState(() => _from = d),
              )),
              const SizedBox(width: 12),
              Expanded(child: _DateField(
                label: 'Date To',
                date: _to,
                onPick: (d) => setState(() => _to = d),
              )),
              const SizedBox(width: 12),
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
            const SizedBox(height: 10),
            Row(children: [
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.search, size: 16),
                label: const Text('Apply Filters'),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _from = DateTime.now().subtract(const Duration(days: 7));
                  _to   = DateTime.now();
                  _deptFilter = '';
                  _records = [];
                  _searched = false;
                }),
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Reset'),
              ),
            ]),
          ]),
        ),
        const Divider(height: 1),

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
                  : !_searched
                      ? const Center(child: Text(
                          'Select date range and click Apply Filters.',
                          style: TextStyle(color: AppColors.textSecondary)))
                      : _filtered.isEmpty
                          ? const Center(child: Text(
                              'No records found for selected filters.',
                              style: TextStyle(
                                  color: AppColors.textSecondary)))
                          : ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 4),
                              itemBuilder: (_, i) => _RecordTile(
                                  record: _filtered[i], index: i + 1),
                            ),
        ),
      ]),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final void Function(DateTime) onPick;
  const _DateField({
    required this.label,
    required this.date,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2024),
          lastDate: DateTime.now(),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          suffixIcon: const Icon(Icons.calendar_today, size: 16),
        ),
        child: Text(DateFormat('dd/MM/yyyy').format(date),
            style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final Map<String, dynamic> record;
  final int index;
  const _RecordTile({required this.record, required this.index});

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

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          SizedBox(width: 28,
            child: Text('$index',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12))),
          NameAvatar(name: record['name'] as String? ?? '?', radius: 18),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(record['name'] as String? ?? '—',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
              Text('${record['employee_id'] ?? ''} · '
                  '${record['department'] ?? ''}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
              Row(children: [
                if (ci != null) ...[
                  const Icon(Icons.login, size: 12, color: AppColors.success),
                  const SizedBox(width: 2),
                  Text(_fmt(ci),
                      style: const TextStyle(fontSize: 11)),
                ],
                if (co != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.logout, size: 12, color: AppColors.error),
                  const SizedBox(width: 2),
                  Text(_fmt(co),
                      style: const TextStyle(fontSize: 11)),
                ],
              ]),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            StatusBadge(status: status),
            if (hrs != null) ...[
              const SizedBox(height: 4),
              Text('${hrs.toStringAsFixed(1)}h',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600)),
            ],
          ]),
        ]),
      ),
    );
  }

  String _fmt(String t) => t.length >= 5 ? t.substring(0, 5) : t;
}
