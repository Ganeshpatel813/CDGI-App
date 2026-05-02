import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../models/attendance.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_widgets.dart';
import '../login_screen.dart';
import 'admin_dashboard_section.dart';
import 'admin_today_section.dart';
import 'admin_all_faculty_section.dart';
import 'admin_add_faculty_section.dart';
import 'admin_attendance_records_section.dart';
import 'admin_monthly_reports_section.dart';
import 'admin_colleges_section.dart';
import 'admin_programs_section.dart';
import 'admin_faculty_mgmt_section.dart';
import 'admin_filter_section.dart';

enum AdminSection {
  dashboard,
  todayAttendance,
  allFaculty,
  addFaculty,
  attendanceRecords,
  monthlyReports,
  colleges,
  programs,
  facultyMgmt,
  attendanceFilter,
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  AdminSection _section = AdminSection.dashboard;

  static const _sectionTitles = {
    AdminSection.dashboard:          'Dashboard',
    AdminSection.todayAttendance:    "Today's Attendance",
    AdminSection.allFaculty:         'All Faculty',
    AdminSection.addFaculty:         'Add Faculty',
    AdminSection.attendanceRecords:  'Attendance Records',
    AdminSection.monthlyReports:     'Monthly Reports',
    AdminSection.colleges:           'Colleges',
    AdminSection.programs:           'Programs',
    AdminSection.facultyMgmt:        'Faculty Management',
    AdminSection.attendanceFilter:   'Attendance Filter',
  };

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;

    if (isWide) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: _appBar(),
        body: Row(children: [
          _Sidebar(
            selected: _section,
            onSelect: (s) => setState(() => _section = s),
          ),
          Expanded(child: _sectionContent()),
        ]),
      );
    }

    // Mobile: drawer overlay
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _appBar(),
      drawer: Drawer(
        child: _Sidebar(
          selected: _section,
          onSelect: (s) {
            Navigator.pop(context); // close drawer
            setState(() => _section = s);
          },
        ),
      ),
      body: _sectionContent(),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
    backgroundColor: AppColors.primary,
    title: Row(mainAxisSize: MainAxisSize.min, children: [
      const Text('Admin Panel',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('👑 Admin Mode',
            style: TextStyle(color: Colors.white, fontSize: 11,
                fontWeight: FontWeight.w700)),
      ),
    ]),
    actions: [
      IconButton(
        icon: const Icon(Icons.logout, color: Colors.white),
        tooltip: 'Logout',
        onPressed: _logout,
      ),
    ],
  );

  Widget _buildSection() {
    return _sectionContent();
  }

  Widget _sectionContent() {
    switch (_section) {
      case AdminSection.dashboard:
        return const AdminDashboardSection();
      case AdminSection.todayAttendance:
        return const AdminTodaySection();
      case AdminSection.allFaculty:
        return const AdminAllFacultySection();
      case AdminSection.addFaculty:
        return AdminAddFacultySection(
          onDone: () => setState(() => _section = AdminSection.allFaculty),
        );
      case AdminSection.attendanceRecords:
        return const AdminAttendanceRecordsSection();
      case AdminSection.monthlyReports:
        return const AdminMonthlyReportsSection();
      case AdminSection.colleges:
        return const AdminCollegesSection();
      case AdminSection.programs:
        return const AdminProgramsSection();
      case AdminSection.facultyMgmt:
        return const AdminFacultyMgmtSection();
      case AdminSection.attendanceFilter:
        return const AdminFilterSection();
    }
  }

  Future<void> _logout() async {
    final auth = context.read<AuthService>();
    try {
      await ApiService(sessionCookie: auth.sessionCookie).logout();
    } catch (_) {}
    await auth.clearSession();
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()));
  }
}

// ── Sidebar ───────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final AdminSection selected;
  final void Function(AdminSection) onSelect;
  const _Sidebar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final faculty = context.watch<AuthService>().faculty!;
    return Container(
      width: 240,
      color: AppColors.primary,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('CDGI',
                      style: TextStyle(color: Colors.white,
                          fontSize: 11, fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Admin Panel',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w800, fontSize: 14)),
                  Text(faculty.name,
                      style: const TextStyle(color: Colors.white60,
                          fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ],
              )),
            ]),
          ),
          const Divider(color: Colors.white12, height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Dashboard section
                _navItem(AdminSection.dashboard,
                    Icons.dashboard_outlined, 'Dashboard'),
                _navItem(AdminSection.todayAttendance,
                    Icons.today_outlined, "Today's Attendance"),
                _navItem(AdminSection.allFaculty,
                    Icons.people_outline, 'All Faculty'),
                _navItem(AdminSection.addFaculty,
                    Icons.person_add_outlined, 'Add Faculty'),
                _navItem(AdminSection.attendanceRecords,
                    Icons.fact_check_outlined, 'Attendance Records'),
                _navItem(AdminSection.monthlyReports,
                    Icons.bar_chart_outlined, 'Monthly Reports'),

                // Management section
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text('MANAGEMENT',
                      style: TextStyle(color: Colors.white38,
                          fontSize: 10, fontWeight: FontWeight.w700,
                          letterSpacing: 1.2)),
                ),
                _navItem(AdminSection.colleges,
                    Icons.school_outlined, 'Colleges'),
                _navItem(AdminSection.programs,
                    Icons.menu_book_outlined, 'Programs'),
                _navItem(AdminSection.facultyMgmt,
                    Icons.manage_accounts_outlined, 'Faculty Mgmt'),
                _navItem(AdminSection.attendanceFilter,
                    Icons.filter_list, 'Attendance Filter',
                    accent: true),
              ],
            ),
          ),

          // Logout
          const Divider(color: Colors.white12, height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red, size: 20),
            title: const Text('Logout',
                style: TextStyle(color: Colors.red, fontSize: 13,
                    fontWeight: FontWeight.w600)),
            onTap: () async {
              final auth = context.read<AuthService>();
              try {
                await ApiService(sessionCookie: auth.sessionCookie).logout();
              } catch (_) {}
              await auth.clearSession();
              if (context.mounted) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _navItem(AdminSection section, IconData icon, String label,
      {bool accent = false}) {
    final isSelected = selected == section;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: accent && isSelected
            ? Border.all(color: AppColors.accent.withOpacity(0.5))
            : null,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon,
            color: isSelected
                ? (accent ? AppColors.accent : Colors.white)
                : Colors.white60,
            size: 18),
        title: Text(label,
            style: TextStyle(
              color: isSelected
                  ? (accent ? AppColors.accent : Colors.white)
                  : Colors.white70,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
            )),
        onTap: () => onSelect(section),
      ),
    );
  }
}

// ── Section wrapper with header ───────────────────────────────────────────────
class SectionPage extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;

  const SectionPage({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary)),
                Text(DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            )),
            if (actions != null) ...actions!,
          ]),
        ),
        const Divider(height: 1),
        Expanded(child: child),
      ],
    );
  }
}
