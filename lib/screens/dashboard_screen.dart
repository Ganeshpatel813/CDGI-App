import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../main.dart';
import '../models/attendance.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/app_widgets.dart';
import 'scan_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: const [
          _OverviewTab(),
          ScanScreen(),
          _CalendarTab(),
          _AttendanceLogTab(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.fingerprint),
              selectedIcon: Icon(Icons.fingerprint), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt), label: 'Log'),
          NavigationDestination(icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final auth = context.read<AuthService>();
    try { await ApiService(sessionCookie: auth.sessionCookie).logout(); } catch (_) {}
    await auth.clearSession();
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()));
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────
class _OverviewTab extends StatefulWidget {
  const _OverviewTab();
  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  MonthlySummary? _summary;
  TodayStatus?    _today;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final auth = context.read<AuthService>();
      final api  = ApiService(sessionCookie: auth.sessionCookie);
      final res  = await Future.wait([
        api.getMonthlySummary(),
        api.getTodayStatus(),
      ]);
      if (mounted) setState(() {
        _summary = res[0] as MonthlySummary;
        _today   = res[1] as TodayStatus;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final faculty = context.watch<AuthService>().faculty!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // ── Greeting header ──────────────────────────────────────────────
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Row(
              children: [
                NameAvatar(name: faculty.name, radius: 28, bg: AppColors.accent),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hello, ${faculty.name.split(' ').first}!',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 18, fontWeight: FontWeight.w700)),
                    Text(faculty.designation,
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                      style: const TextStyle(color: Colors.white60, fontSize: 11)),
                  ],
                )),
              ],
            ),
          ),

          if (_loading)
            const Padding(padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Padding(padding: const EdgeInsets.all(20),
              child: Column(children: [
                ErrorBox(message: _error!),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _load, child: const Text('Retry')),
              ]))
          else ...[
            // ── Today's status ───────────────────────────────────────────
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _TodayCard(status: _today!),
            ),

            // ── Monthly stats ────────────────────────────────────────────
            SectionHeader(
              title: 'This Month — ${DateFormat('MMMM yyyy').format(DateTime.now())}',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(children: [
                Expanded(child: StatCard(label: 'Present',
                    value: '${_summary!.present}',
                    color: AppColors.success, icon: Icons.check_circle_outline)),
                Expanded(child: StatCard(label: 'Absent',
                    value: '${_summary!.absent}',
                    color: AppColors.error, icon: Icons.cancel_outlined)),
                Expanded(child: StatCard(label: 'Half Day',
                    value: '${_summary!.halfDay}',
                    color: AppColors.warning, icon: Icons.timelapse)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(children: [
                Expanded(child: StatCard(label: 'Avg Hours',
                    value: '${_summary!.avgWorkingHours.toStringAsFixed(1)}h',
                    color: AppColors.primary, icon: Icons.access_time)),
                Expanded(child: StatCard(label: 'Attendance',
                    value: '${_summary!.attendancePercent.toStringAsFixed(0)}%',
                    color: AppColors.accent, icon: Icons.percent)),
                Expanded(child: StatCard(label: 'Work Days',
                    value: '${_summary!.workingDays}',
                    color: AppColors.textSecondary, icon: Icons.calendar_today)),
              ]),
            ),

            // ── Attendance rate bar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Text('Attendance Rate',
                          style: TextStyle(fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                        const Spacer(),
                        Text('${_summary!.attendancePercent.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: _summary!.attendancePercent >= 75
                                ? AppColors.success : AppColors.warning,
                          )),
                      ]),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _summary!.attendancePercent / 100,
                          minHeight: 12,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(
                            _summary!.attendancePercent >= 75
                                ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_summary!.present + _summary!.halfDay} present of ${_summary!.workingDays} working days',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final TodayStatus status;
  const _TodayCard({required this.status});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (!status.hasRecord) {
      statusColor = AppColors.textSecondary;
      statusIcon  = Icons.radio_button_unchecked;
      statusText  = 'Not marked yet';
    } else if (status.hasOpenSession) {
      statusColor = AppColors.success;
      statusIcon  = Icons.login;
      statusText  = 'Checked In';
    } else {
      switch (status.status) {
        case 'present':  statusColor = AppColors.success; statusIcon = Icons.check_circle; statusText = 'Present';  break;
        case 'half_day': statusColor = AppColors.warning; statusIcon = Icons.timelapse;    statusText = 'Half Day'; break;
        default:         statusColor = AppColors.error;   statusIcon = Icons.cancel;       statusText = 'Absent';
      }
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.today, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              const Text("Today's Attendance",
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(statusIcon, color: statusColor, size: 14),
                  const SizedBox(width: 4),
                  Text(statusText, style: TextStyle(
                    color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
            if (status.hasRecord) ...[
              const Divider(height: 20),
              Row(children: [
                _chip(Icons.login, 'In',
                  status.sessions.isNotEmpty ? status.sessions.first.checkInTime.substring(0,5) : '—'),
                _chip(Icons.logout, 'Out',
                  status.sessions.isNotEmpty && status.sessions.last.checkOutTime != null
                      ? status.sessions.last.checkOutTime!.substring(0,5) : '—'),
                _chip(Icons.access_time, 'Hours',
                  status.workingHours != null
                      ? '${status.workingHours!.toStringAsFixed(1)}h' : '—'),
                _chip(Icons.repeat, 'Sessions', '${status.sessionCount}'),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, String value) => Expanded(
    child: Column(children: [
      Icon(icon, size: 16, color: AppColors.textSecondary),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      Text(value, style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    ]),
  );
}

// ─── Calendar Tab ─────────────────────────────────────────────────────────────
class _CalendarTab extends StatefulWidget {
  const _CalendarTab();
  @override
  State<_CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<_CalendarTab> {
  DateTime _focused = DateTime.now();
  List<dynamic> _calendar = [];
  MonthlySummary? _summary;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  String get _monthStr => DateFormat('yyyy-MM').format(_focused);

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      final api  = ApiService(sessionCookie: auth.sessionCookie);
      final res  = await Future.wait([
        api.getCalendar(month: _monthStr),
        api.getMonthlySummary(month: _monthStr),
      ]);
      if (mounted) setState(() {
        _calendar = res[0] as List<dynamic>;
        _summary  = res[1] as MonthlySummary;
        _loading  = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<DateTime, Map<String, dynamic>> statusMap = {};
    for (final r in _calendar) {
      final d = DateTime.tryParse(r['attendance_date'] as String? ?? '');
      if (d != null) statusMap[DateTime(d.year, d.month, d.day)] = r as Map<String, dynamic>;
    }

    return Column(
      children: [
        // Month nav
        Container(
          color: AppColors.primary,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () {
                  setState(() => _focused = DateTime(_focused.year, _focused.month - 1));
                  _load();
                },
              ),
              Text(DateFormat('MMMM yyyy').format(_focused),
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: () {
                  final now = DateTime.now();
                  if (_focused.year == now.year && _focused.month == now.month) return;
                  setState(() => _focused = DateTime(_focused.year, _focused.month + 1));
                  _load();
                },
              ),
            ],
          ),
        ),

        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Legend
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _legend(AppColors.success, 'Present'),
                        const SizedBox(width: 16),
                        _legend(AppColors.warning, 'Half Day'),
                        const SizedBox(width: 16),
                        _legend(AppColors.error, 'Absent'),
                      ],
                    ),
                  ),
                  TableCalendar(
                    firstDay: DateTime(_focused.year, _focused.month, 1),
                    lastDay: DateTime(_focused.year, _focused.month + 1, 0),
                    focusedDay: _focused,
                    headerVisible: false,
                    calendarStyle: const CalendarStyle(
                      outsideDaysVisible: false,
                      weekendTextStyle: TextStyle(color: AppColors.error),
                    ),
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (ctx, day, _) {
                        final key    = DateTime(day.year, day.month, day.day);
                        final record = statusMap[key];
                        final status = record?['status'] as String?;
                        Color? bg;
                        if (status == 'present')  bg = AppColors.success.withOpacity(0.2);
                        if (status == 'half_day') bg = AppColors.warning.withOpacity(0.2);
                        if (status == 'absent')   bg = AppColors.error.withOpacity(0.15);
                        final ci = record?['check_in_time'] as String?;
                        return GestureDetector(
                          onTap: record != null ? () => _showDetail(record) : null,
                          child: Container(
                            margin: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: bg, shape: BoxShape.circle),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${day.day}', style: TextStyle(
                                  fontSize: 13,
                                  color: bg != null
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                  fontWeight: bg != null
                                      ? FontWeight.w700 : FontWeight.normal,
                                )),
                                if (ci != null)
                                  Text(ci.substring(0,5), style: const TextStyle(
                                    fontSize: 8, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Summary cards
                  if (_summary != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                      child: Row(children: [
                        Expanded(child: StatCard(label: 'Present',
                            value: '${_summary!.present}',
                            color: AppColors.success, icon: Icons.check_circle_outline)),
                        Expanded(child: StatCard(label: 'Half Day',
                            value: '${_summary!.halfDay}',
                            color: AppColors.warning, icon: Icons.timelapse)),
                        Expanded(child: StatCard(label: 'Absent',
                            value: '${_summary!.absent}',
                            color: AppColors.error, icon: Icons.cancel_outlined)),
                      ]),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _legend(Color color, String label) => Row(children: [
    Container(width: 12, height: 12,
      decoration: BoxDecoration(color: color.withOpacity(0.3),
          shape: BoxShape.circle,
          border: Border.all(color: color))),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
  ]);

  void _showDetail(Map<String, dynamic> r) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r['attendance_date'] as String? ?? '',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Row(children: [
              _detailCard('Check In', r['check_in_time'] as String? ?? '—',
                  AppColors.success),
              const SizedBox(width: 8),
              _detailCard('Check Out', r['check_out_time'] as String? ?? '—',
                  const Color(0xFF7C3AED)),
              const SizedBox(width: 8),
              _detailCard('Hours',
                  '${(r['working_hours'] as num?)?.toStringAsFixed(1) ?? '0'}h',
                  AppColors.info),
            ]),
            const SizedBox(height: 16),
            StatusBadge(status: r['status'] as String? ?? 'absent'),
          ],
        ),
      ),
    );
  }

  Widget _detailCard(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(children: [
        Text(label, style: TextStyle(fontSize: 11, color: color)),
        const SizedBox(height: 4),
        Text(value.length >= 5 ? value.substring(0,5) : value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
      ]),
    ),
  );
}

// ─── Attendance Log Tab ───────────────────────────────────────────────────────
class _AttendanceLogTab extends StatefulWidget {
  const _AttendanceLogTab();
  @override
  State<_AttendanceLogTab> createState() => _AttendanceLogTabState();
}

class _AttendanceLogTabState extends State<_AttendanceLogTab> {
  DateTime _focused = DateTime.now();
  List<dynamic> _records = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  String get _monthStr => DateFormat('yyyy-MM').format(_focused);

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final auth = context.read<AuthService>();
      final api  = ApiService(sessionCookie: auth.sessionCookie);
      final rows = await api.getMyReport(month: _monthStr);
      if (mounted) setState(() {
        _records = rows.map((r) => r.toJson()).toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.primary,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () {
                  setState(() => _focused = DateTime(_focused.year, _focused.month - 1));
                  _load();
                },
              ),
              Text(DateFormat('MMMM yyyy').format(_focused),
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: () {
                  final now = DateTime.now();
                  if (_focused.year == now.year && _focused.month == now.month) return;
                  setState(() => _focused = DateTime(_focused.year, _focused.month + 1));
                  _load();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      ErrorBox(message: _error!),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ]))
                  : _records.isEmpty
                      ? const Center(child: Text('No records for this month.',
                          style: TextStyle(color: AppColors.textSecondary)))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: _records.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 2),
                            itemBuilder: (_, i) => AttendanceTile(record: _records[i]),
                          ),
                        ),
        ),
      ],
    );
  }
}

// ─── Profile Tab ──────────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final faculty = context.watch<AuthService>().faculty!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(child: NameAvatar(name: faculty.name, radius: 48)),
        const SizedBox(height: 12),
        Center(child: Text(faculty.name,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
              color: AppColors.textPrimary))),
        Center(child: Text(faculty.designation,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
        const SizedBox(height: 24),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              InfoRow(icon: Icons.badge_outlined, label: 'Employee ID', value: faculty.employeeId),
              const Divider(),
              InfoRow(icon: Icons.email_outlined, label: 'Email', value: faculty.email),
              if (faculty.phone != null && faculty.phone!.isNotEmpty) ...[
                const Divider(),
                InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: faculty.phone!),
              ],
              const Divider(),
              InfoRow(icon: Icons.category_outlined, label: 'Department', value: faculty.department),
              const Divider(),
              InfoRow(icon: Icons.school_outlined, label: 'Designation', value: faculty.designation),
              if (faculty.createdAt != null) ...[
                const Divider(),
                InfoRow(icon: Icons.calendar_today, label: 'Joined',
                    value: faculty.createdAt!.split(' ').first),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}
