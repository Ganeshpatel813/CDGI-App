import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_widgets.dart';
import 'admin_screen.dart';

class AdminFilterSection extends StatefulWidget {
  const AdminFilterSection({super.key});
  @override
  State<AdminFilterSection> createState() => _AdminFilterSectionState();
}

class _AdminFilterSectionState extends State<AdminFilterSection> {
  // Filter values
  int? _collegeId;
  int? _programId;
  String _designation = '';
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to   = DateTime.now();
  String? _month;
  String _viewMode = 'summary';

  // Data
  List<dynamic> _colleges  = [];
  List<dynamic> _programs  = [];
  List<dynamic> _results   = [];
  bool _loading    = false;
  bool _loadingMeta = true;
  String? _error;
  bool _applied = false;

  static const _designations = [
    'All Designations',
    'Professor',
    'Associate Professor',
    'Assistant Professor',
    'Lecturer',
  ];

  @override
  void initState() { super.initState(); _loadMeta(); }

  Future<void> _loadMeta() async {
    try {
      final auth = context.read<AuthService>();
      final list = await ApiService(sessionCookie: auth.sessionCookie)
          .getColleges();
      if (mounted) setState(() { _colleges = list; _loadingMeta = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingMeta = false);
    }
  }

  Future<void> _apply() async {
    setState(() { _loading = true; _error = null; _applied = true; });
    try {
      final auth = context.read<AuthService>();
      final api  = ApiService(sessionCookie: auth.sessionCookie);

      // Build query params
      final q = <String, String>{};
      if (_collegeId != null) q['collegeId'] = '$_collegeId';
      if (_programId != null) q['programId'] = '$_programId';
      if (_designation.isNotEmpty && _designation != 'All Designations')
        q['designation'] = _designation;
      if (_month != null) {
        q['month'] = _month!;
      } else {
        q['from'] = DateFormat('yyyy-MM-dd').format(_from);
        q['to']   = DateFormat('yyyy-MM-dd').format(_to);
      }
      q['mode'] = _viewMode;

      final r = await api.getAdvancedReport(q);
      if (mounted) setState(() {
        _results = _viewMode == 'summary'
            ? (r['faculty'] as List<dynamic>? ?? [])
            : (r['records'] as List<dynamic>? ?? []);
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _reset() => setState(() {
    _collegeId   = null;
    _programId   = null;
    _designation = '';
    _from = DateTime.now().subtract(const Duration(days: 30));
    _to   = DateTime.now();
    _month       = null;
    _viewMode    = 'summary';
    _results     = [];
    _applied     = false;
    _error       = null;
  });

  @override
  Widget build(BuildContext context) {
    return SectionPage(
      title: 'Attendance Filter',
      child: Column(children: [
        // Filter panel
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: College, Program, Designation, View Mode
              Row(children: [
                Expanded(child: _loadingMeta
                    ? const LinearProgressIndicator()
                    : DropdownButtonFormField<int>(
                        value: _collegeId,
                        decoration: const InputDecoration(
                            labelText: 'College', isDense: true),
                        items: [
                          const DropdownMenuItem(value: null,
                              child: Text('All Colleges')),
                          ..._colleges.map((c) => DropdownMenuItem<int>(
                              value: c['id'] as int,
                              child: Text(c['short_name'] as String? ?? '',
                                  overflow: TextOverflow.ellipsis))),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _collegeId = v;
                            _programId = null;
                            if (v != null) {
                              final col = _colleges.firstWhere(
                                  (c) => c['id'] == v, orElse: () => null);
                              _programs = col?['programs'] as List<dynamic>? ?? [];
                            } else {
                              _programs = [];
                            }
                          });
                        },
                      )),
                const SizedBox(width: 10),
                Expanded(child: DropdownButtonFormField<int>(
                  value: _programId,
                  decoration: const InputDecoration(
                      labelText: 'Course / Program', isDense: true),
                  items: [
                    const DropdownMenuItem(value: null,
                        child: Text('All Programs')),
                    ..._programs.map((p) => DropdownMenuItem<int>(
                        value: p['id'] as int,
                        child: Text(p['name'] as String? ?? '',
                            overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (v) => setState(() => _programId = v),
                )),
                const SizedBox(width: 10),
                Expanded(child: DropdownButtonFormField<String>(
                  value: _designation.isEmpty ? null : _designation,
                  decoration: const InputDecoration(
                      labelText: 'Designation', isDense: true),
                  items: _designations.map((d) => DropdownMenuItem(
                      value: d == 'All Designations' ? null : d,
                      child: Text(d, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setState(() => _designation = v ?? ''),
                )),
                const SizedBox(width: 10),
                Expanded(child: DropdownButtonFormField<String>(
                  value: _viewMode,
                  decoration: const InputDecoration(
                      labelText: 'View Mode', isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'summary',
                        child: Text('Summary (Attendance %)')),
                    DropdownMenuItem(value: 'detail',
                        child: Text('Detail (All Records)')),
                  ],
                  onChanged: (v) => setState(() => _viewMode = v ?? 'summary'),
                )),
              ]),
              const SizedBox(height: 12),

              // Row 2: Date From, Date To, Month
              Row(children: [
                Expanded(child: _DateField(
                  label: 'Date From',
                  date: _from,
                  onPick: (d) => setState(() { _from = d; _month = null; }),
                )),
                const SizedBox(width: 10),
                Expanded(child: _DateField(
                  label: 'Date To',
                  date: _to,
                  onPick: (d) => setState(() { _to = d; _month = null; }),
                )),
                const SizedBox(width: 10),
                Expanded(child: GestureDetector(
                  onTap: _pickMonth,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Or Month', isDense: true,
                        suffixIcon: Icon(Icons.arrow_drop_down, size: 18)),
                    child: Text(
                      _month != null
                          ? DateFormat('MMMM yyyy').format(
                              DateTime.parse('$_month-01'))
                          : '— Pick Month —',
                      style: TextStyle(
                          fontSize: 13,
                          color: _month != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary),
                    ),
                  ),
                )),
                const SizedBox(width: 10),
                const Expanded(child: SizedBox()),
              ]),
              const SizedBox(height: 12),

              // Buttons
              Row(children: [
                ElevatedButton.icon(
                  onPressed: _apply,
                  icon: const Icon(Icons.search, size: 16),
                  label: const Text('Apply Filters'),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Reset'),
                ),
              ]),
            ],
          ),
        ),
        const Divider(height: 1),

        // Results
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        ErrorBox(message: _error!),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _apply,
                            child: const Text('Retry')),
                      ])))
                  : !_applied
                      ? const Center(child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.filter_list, size: 48,
                                color: AppColors.textSecondary),
                            SizedBox(height: 12),
                            Text('Set filters and click Apply Filters',
                                style: TextStyle(
                                    color: AppColors.textSecondary)),
                          ]))
                      : _results.isEmpty
                          ? const Center(child: Text(
                              'No results for selected filters.',
                              style: TextStyle(
                                  color: AppColors.textSecondary)))
                          : _viewMode == 'summary'
                              ? _SummaryResults(results: _results)
                              : _DetailResults(results: _results),
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
          width: 280,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, childAspectRatio: 2),
            itemCount: 12,
            itemBuilder: (_, i) {
              final m = DateTime(now.year, i + 1);
              final ms = DateFormat('yyyy-MM').format(m);
              final isSel = ms == _month;
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _month = ms);
                },
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: isSel ? AppColors.primary : AppColors.divider),
                  ),
                  child: Center(child: Text(DateFormat('MMM').format(m),
                      style: TextStyle(fontSize: 12,
                          color: isSel ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSel
                              ? FontWeight.w700 : FontWeight.normal))),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Summary Results ───────────────────────────────────────────────────────────
class _SummaryResults extends StatelessWidget {
  final List<dynamic> results;
  const _SummaryResults({required this.results});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Header
      Container(
        color: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: const Row(children: [
          _TH('#', flex: 1),
          _TH('NAME', flex: 3),
          _TH('EMP. ID', flex: 2),
          _TH('DEPARTMENT', flex: 4),
          _TH('PRESENT', flex: 2),
          _TH('ABSENT', flex: 2),
          _TH('HALF DAY', flex: 2),
          _TH('ATTEND %', flex: 2),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          itemCount: results.length,
          itemBuilder: (_, i) {
            final r       = results[i];
            final present = (r['present']      as num?)?.toInt() ?? 0;
            final absent  = (r['absent']       as num?)?.toInt() ?? 0;
            final half    = (r['half_day']     as num?)?.toInt() ?? 0;
            final wdays   = (r['working_days'] as num?)?.toInt() ?? 0;
            final pct     = wdays > 0
                ? ((present + half * 0.5) / wdays * 100).clamp(0, 100)
                : 0.0;
            return Container(
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: i.isEven ? Colors.grey.shade50 : Colors.white,
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(children: [
                _TD('${i + 1}', flex: 1,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                _TD(r['name'] as String? ?? '—', flex: 3,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12)),
                _TD(r['employeeId'] as String? ?? '—', flex: 2,
                    style: const TextStyle(
                        color: AppColors.accent, fontSize: 11,
                        fontWeight: FontWeight.w600)),
                _TD(r['department'] as String? ?? '—', flex: 4,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                _colorNum(present, AppColors.success, flex: 2),
                _colorNum(absent, AppColors.error, flex: 2),
                _colorNum(half, AppColors.warning, flex: 2),
                Expanded(flex: 2, child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 8),
                  child: Text('${pct.toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: pct >= 75
                              ? AppColors.success : AppColors.error)),
                )),
              ]),
            );
          },
        ),
      ),
    ]);
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
          child: Text('$val', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w800, color: color)),
        ),
      ));
}

// ── Detail Results ────────────────────────────────────────────────────────────
class _DetailResults extends StatelessWidget {
  final List<dynamic> results;
  const _DetailResults({required this.results});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (_, i) {
        final r      = results[i];
        final status = r['status'] as String? ?? 'absent';
        final ci     = r['check_in_time']  as String?;
        final co     = r['check_out_time'] as String?;
        final hrs    = (r['working_hours'] as num?)?.toDouble();
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              NameAvatar(name: r['name'] as String? ?? '?', radius: 20),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r['name'] as String? ?? '—',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  Text('${r['employee_id'] ?? ''} · '
                      '${r['attendance_date'] ?? ''}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                  Row(children: [
                    if (ci != null) ...[
                      const Icon(Icons.login, size: 12,
                          color: AppColors.success),
                      const SizedBox(width: 2),
                      Text(_fmt(ci), style: const TextStyle(fontSize: 11)),
                    ],
                    if (co != null) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.logout, size: 12,
                          color: AppColors.error),
                      const SizedBox(width: 2),
                      Text(_fmt(co), style: const TextStyle(fontSize: 11)),
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
      },
    );
  }

  String _fmt(String t) => t.length >= 5 ? t.substring(0, 5) : t;
}

// ── Shared helpers ────────────────────────────────────────────────────────────
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
          suffixIcon: const Icon(Icons.calendar_today, size: 14),
        ),
        child: Text(DateFormat('dd/MM/yyyy').format(date),
            style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}
