import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_widgets.dart';
import 'admin_screen.dart';

class AdminProgramsSection extends StatefulWidget {
  const AdminProgramsSection({super.key});
  @override
  State<AdminProgramsSection> createState() => _AdminProgramsSectionState();
}

class _AdminProgramsSectionState extends State<AdminProgramsSection> {
  List<dynamic> _colleges = [];
  int? _selectedCollege;
  List<dynamic> get _programs {
    if (_selectedCollege == null) {
      return _colleges.expand((c) =>
          (c['programs'] as List<dynamic>? ?? []).map((p) => {
            ...p as Map<String, dynamic>,
            'college_name': c['short_name'],
          })).toList();
    }
    final col = _colleges.firstWhere(
        (c) => c['id'] == _selectedCollege, orElse: () => null);
    return (col?['programs'] as List<dynamic>? ?? []).map((p) => {
      ...p as Map<String, dynamic>,
      'college_name': col?['short_name'],
    }).toList();
  }

  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final auth = context.read<AuthService>();
      final list = await ApiService(sessionCookie: auth.sessionCookie)
          .getColleges();
      if (mounted) setState(() { _colleges = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionPage(
      title: 'Programs',
      child: Column(children: [
        // College filter
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(children: [
            Expanded(child: _loading
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<int>(
                    value: _selectedCollege,
                    decoration: const InputDecoration(
                        hintText: 'All Colleges', isDense: true),
                    items: [
                      const DropdownMenuItem(value: null,
                          child: Text('All Colleges')),
                      ..._colleges.map((c) => DropdownMenuItem<int>(
                          value: c['id'] as int,
                          child: Text(c['name'] as String? ?? ''))),
                    ],
                    onChanged: (v) => setState(() => _selectedCollege = v),
                  )),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: () => _showDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Program'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(120, 40)),
            ),
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
                  : _programs.isEmpty
                      ? const Center(child: Text('No programs found.',
                          style: TextStyle(color: AppColors.textSecondary)))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: _programs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 4),
                            itemBuilder: (_, i) => _ProgramTile(
                              program: _programs[i],
                              index: i + 1,
                              colleges: _colleges,
                              onEdit: () => _showDialog(program: _programs[i]),
                              onDelete: () => _delete(_programs[i]),
                            ),
                          ),
                        ),
        ),
      ]),
    );
  }

  void _showDialog({Map<String, dynamic>? program}) {
    int? collegeId = program?['college_id'] as int?;
    final nameCtrl     = TextEditingController(
        text: program?['name'] as String? ?? '');
    final durationCtrl = TextEditingController(
        text: program?['duration'] as String? ?? '');
    final intakeCtrl   = TextEditingController(
        text: program?['intake_capacity']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(program == null ? 'Add Program' : 'Edit Program'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<int>(
              value: collegeId,
              decoration: const InputDecoration(labelText: 'College *'),
              items: _colleges.map((c) => DropdownMenuItem<int>(
                  value: c['id'] as int,
                  child: Text(c['name'] as String? ?? ''))).toList(),
              onChanged: (v) => setS(() => collegeId = v),
            ),
            const SizedBox(height: 12),
            TextField(controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Program Name *')),
            const SizedBox(height: 12),
            TextField(controller: durationCtrl,
                decoration: const InputDecoration(
                    labelText: 'Duration (e.g. 3 Years)')),
            const SizedBox(height: 12),
            TextField(controller: intakeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Intake Capacity')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (collegeId == null || nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(context);
                await _save(
                  id: program?['id'] as int?,
                  collegeId: collegeId!,
                  name: nameCtrl.text.trim(),
                  duration: durationCtrl.text.trim(),
                  intake: int.tryParse(intakeCtrl.text.trim()) ?? 0,
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save({int? id, required int collegeId,
      required String name, required String duration,
      required int intake}) async {
    try {
      final auth = context.read<AuthService>();
      final api  = ApiService(sessionCookie: auth.sessionCookie);
      if (id == null) {
        await api.addProgram(collegeId: collegeId, name: name,
            duration: duration, intake: intake);
      } else {
        await api.updateProgram(id: id, name: name,
            duration: duration, intake: intake);
      }
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()),
              backgroundColor: AppColors.error));
    }
  }

  Future<void> _delete(Map<String, dynamic> p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Program'),
        content: Text('Delete ${p['name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final auth = context.read<AuthService>();
      await ApiService(sessionCookie: auth.sessionCookie)
          .deleteProgram(p['id'] as int);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()),
              backgroundColor: AppColors.error));
    }
  }
}

class _ProgramTile extends StatelessWidget {
  final Map<String, dynamic> program;
  final int index;
  final List<dynamic> colleges;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ProgramTile({
    required this.program,
    required this.index,
    required this.colleges,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text('$index',
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w800)),
        ),
        title: Text(program['name'] as String? ?? '—',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${program['college_name'] ?? ''}'
          '${program['duration'] != null ? ' · ${program['duration']}' : ''}'
          '${program['intake_capacity'] != null ? ' · Intake: ${program['intake_capacity']}' : ''}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit',
              child: Row(children: [
                Icon(Icons.edit, size: 16, color: AppColors.primary),
                SizedBox(width: 8), Text('Edit'),
              ])),
            const PopupMenuItem(value: 'delete',
              child: Row(children: [
                Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: AppColors.error)),
              ])),
          ],
        ),
      ),
    );
  }
}
