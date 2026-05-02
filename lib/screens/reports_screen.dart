import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../main.dart';
import '../models/attendance.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/app_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  DateTime _focusedMonth = DateTime.now();

  MonthlySummary? _summary;
  List<AttendanceRecord> _records = [];
  List<dynamic> _calendar = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String get _monthStr => DateFormat('yyyy-MM').format(_focusedMonth);

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final auth = context.read<AuthService>();
      final api  = ApiService(sessionCookie: auth.sessionCookie);
      final results = await Future.wait([
        api.getMonthlySummary(month: _monthStr),
        api.getMyReport(month: _monthStr),
        api.getCalendar(month: _monthStr),
      ]);
      if (mounted) {
        setState(() {
          _summary  = results[0] as MonthlySummary;
          _records  = results[1] as List<AttendanceRecord>;
          _calendar = results[2] as List<dynamic>;
          _loading  = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _prevMonth() {
    setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1));
    _load();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_focusedMonth.year == now.year && _focusedMonth.month == now.month) return;
    setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.accent,
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Calendar'),
            Tab(text: 'Log'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Month navigator
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: _prevMonth,
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_focusedMonth),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, style: const TextStyle(color: AppColors.error)),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _load, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : TabBarView(
                        controller: _tabs,
                        children: [
                          _buildSummaryTab(),
                          _buildCalendarTab(),
                          _buildLogTab(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  // ── Summary Tab ───────────────────────────────────────────────────────────

  Widget _buildSummaryTab() {
    if (_summary == null) return const SizedBox();
    final s = _summary!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats grid
        Row(
          children: [
            Expanded(child: StatCard(label: 'Present', value: '${s.present}', color: AppColors.success, icon: Icons.check_circle_outline)),
            Expanded(child: StatCard(label: 'Absent', value: '${s.absent}', color: AppColors.error, icon: Icons.cancel_outlined)),
          ],
        ),
        Row(
          children: [
            Expanded(child: StatCard(label: 'Half Day', value: '${s.halfDay}', color: AppColors.warning, icon: Icons.timelapse)),
            Expanded(child: StatCard(label: 'Work Days', value: '${s.workingDays}', color: AppColors.primary, icon: Icons.calendar_today)),
          ],
        ),
        Row(
          children: [
            Expanded(child: StatCard(label: 'Avg Hours', value: '${s.avgWorkingHours.toStringAsFixed(1)}h', color: AppColors.accent, icon: Icons.access_time)),
            Expanded(child: StatCard(label: 'Attendance %', value: '${s.attendancePercent.toStringAsFixed(1)}%', color: AppColors.textSecondary, icon: Icons.percent)),
          ],
        ),
        const SizedBox(height: 16),

        // Attendance bar
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Attendance Rate', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: s.attendancePercent / 100,
                    minHeight: 14,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(
                      s.attendancePercent >= 75 ? AppColors.success : AppColors.warning,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${s.attendancePercent.toStringAsFixed(1)}% — ${s.present + s.halfDay} of ${s.workingDays} working days',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Calendar Tab ──────────────────────────────────────────────────────────

  Widget _buildCalendarTab() {
    // Build a map of date → status
    final Map<DateTime, String> statusMap = {};
    for (final r in _calendar) {
      final d = DateTime.tryParse(r['attendance_date'] as String? ?? '');
      if (d != null) statusMap[DateTime(d.year, d.month, d.day)] = r['status'] as String? ?? '';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: TableCalendar(
        firstDay: DateTime(_focusedMonth.year, _focusedMonth.month, 1),
        lastDay: DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0),
        focusedDay: _focusedMonth,
        headerVisible: false,
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: TextStyle(color: AppColors.error),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (ctx, day, focused) {
            final key    = DateTime(day.year, day.month, day.day);
            final status = statusMap[key];
            Color? bg;
            if (status == 'present')  bg = AppColors.success.withOpacity(0.2);
            if (status == 'half_day') bg = AppColors.warning.withOpacity(0.2);
            if (status == 'absent')   bg = AppColors.error.withOpacity(0.15);

            return Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 13,
                    color: bg != null ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: bg != null ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Log Tab ───────────────────────────────────────────────────────────────

  Widget _buildLogTab() {
    if (_records.isEmpty) {
      return const Center(
        child: Text('No attendance records for this month.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) => _RecordTile(record: _records[i]),
    );
  }
}

// ─── Record Tile ──────────────────────────────────────────────────────────────

class _RecordTile extends StatelessWidget {
  final AttendanceRecord record;
  const _RecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    switch (record.status) {
      case 'present':  statusColor = AppColors.success; statusIcon = Icons.check_circle; break;
      case 'half_day': statusColor = AppColors.warning; statusIcon = Icons.timelapse;    break;
      default:         statusColor = AppColors.error;   statusIcon = Icons.cancel;
    }

    final date = DateTime.tryParse(record.attendanceDate);
    final dateStr = date != null ? DateFormat('EEE, d MMM').format(date) : record.attendanceDate;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (record.checkInTime != null)
                        Text('In: ${record.checkInTime!.substring(0, 5)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      if (record.checkOutTime != null) ...[
                        const SizedBox(width: 8),
                        Text('Out: ${record.checkOutTime!.substring(0, 5)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  record.status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700),
                ),
                if (record.workingHours != null)
                  Text(
                    '${record.workingHours!.toStringAsFixed(1)}h',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
