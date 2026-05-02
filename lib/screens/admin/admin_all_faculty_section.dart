import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../models/faculty.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_widgets.dart';
import 'admin_screen.dart';

class AdminAllFacultySection extends StatefulWidget {
  const AdminAllFacultySection({super.key});
  @override
  State<AdminAllFacultySection> createState() => _AdminAllFacultySectionState();
}

class _AdminAllFacultySectionState extends State<AdminAllFacultySection> {
  List<Faculty> _faculty = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();
  String _deptFilter = '';
  List<String> _departments = [];

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load({String? search}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final auth = context.read<AuthService>();
      final list = await ApiService(sessionCookie: auth.sessionCookie)
          .getAdminFaculty(search: search);
      if (mounted) {
        final depts = list.map((f) => f.department)
            .toSet().where((d) => d.isNotEmpty).toList()..sort();
        setState(() {
          _faculty     = list;
          _departments = depts;
          _loading     = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<Faculty> get _filtered => _deptFilter.isEmpty
      ? _faculty
      : _faculty.where((f) => f.department == _deptFilter).toList();

  @override
  Widget build(BuildContext context) {
    return SectionPage(
      title: 'All Faculty',
      child: Column(children: [
        // Search + filter bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search name or ID…',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () { _searchCtrl.clear(); _load(); })
                      : null,
                ),
                onSubmitted: (v) => _load(search: v.trim()),
                onChanged: (v) { if (v.isEmpty) _load(); },
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

        // Count
        if (!_loading && _error == null)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(children: [
              Text('${_filtered.length} faculty',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),

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
                      ? const Center(child: Text('No faculty found.',
                          style: TextStyle(color: AppColors.textSecondary)))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 4),
                            itemBuilder: (_, i) => _FacultyCard(
                              faculty: _filtered[i],
                              index: i + 1,
                              onToggle: () => _toggle(_filtered[i]),
                              onDelete: () => _delete(_filtered[i]),
                            ),
                          ),
                        ),
        ),
      ]),
    );
  }

  Future<void> _toggle(Faculty f) async {
    try {
      final auth = context.read<AuthService>();
      await ApiService(sessionCookie: auth.sessionCookie).toggleFaculty(f.id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()),
              backgroundColor: AppColors.error));
    }
  }

  Future<void> _delete(Faculty f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Faculty'),
        content: Text(
            'Delete ${f.name} (${f.employeeId})?\nThis cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final auth = context.read<AuthService>();
      await ApiService(sessionCookie: auth.sessionCookie).deleteFaculty(f.id);
      _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Faculty deleted.'),
              backgroundColor: AppColors.success));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()),
              backgroundColor: AppColors.error));
    }
  }
}

class _FacultyCard extends StatelessWidget {
  final Faculty faculty;
  final int index;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  const _FacultyCard({
    required this.faculty,
    required this.index,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = faculty.isActive ?? true;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          // Index
          SizedBox(width: 28,
            child: Text('$index',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12))),
          // Avatar
          NameAvatar(name: faculty.name, radius: 22,
              bg: isActive ? AppColors.primary : Colors.grey),
          const SizedBox(width: 12),
          // Info
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(faculty.name,
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13,
                        color: isActive
                            ? AppColors.textPrimary
                            : AppColors.textSecondary))),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isActive
                        ? AppColors.success : AppColors.error)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: isActive
                              ? AppColors.success : AppColors.error)),
                ),
              ]),
              const SizedBox(height: 2),
              Text('${faculty.employeeId} · ${faculty.department}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
              Text('${faculty.designation} · ${faculty.email}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis),
            ],
          )),
          // Actions
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'toggle') onToggle();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'toggle',
                child: Row(children: [
                  Icon(isActive ? Icons.block : Icons.check_circle_outline,
                      size: 16,
                      color: isActive ? AppColors.warning : AppColors.success),
                  const SizedBox(width: 8),
                  Text(isActive ? 'Deactivate' : 'Activate'),
                ])),
              const PopupMenuItem(value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Delete',
                      style: TextStyle(color: AppColors.error)),
                ])),
            ],
          ),
        ]),
      ),
    );
  }
}
