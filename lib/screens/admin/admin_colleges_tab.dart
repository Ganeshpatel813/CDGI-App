import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_widgets.dart';

class AdminCollegesTab extends StatefulWidget {
  const AdminCollegesTab({super.key});
  @override
  State<AdminCollegesTab> createState() => _AdminCollegesTabState();
}

class _AdminCollegesTabState extends State<AdminCollegesTab> {
  List<dynamic> _colleges = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final auth = context.read<AuthService>();
      final list = await ApiService(sessionCookie: auth.sessionCookie).getColleges();
      if (mounted) setState(() { _colleges = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  ErrorBox(message: _error!),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ])))
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(children: [
                      const Text('Colleges & Programs',
                        style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary)),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => _showCollegeDialog(),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(80, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    ..._colleges.map((c) => _CollegeCard(
                      college: c,
                      onEdit: () => _showCollegeDialog(college: c),
                      onDelete: () => _deleteCollege(c),
                      onAddProgram: () => _showProgramDialog(collegeId: c['id']),
                    )),
                  ],
                ),
              );
  }

  void _showCollegeDialog({Map<String, dynamic>? college}) {
    final nameCtrl  = TextEditingController(text: college?['name'] as String? ?? '');
    final shortCtrl = TextEditingController(text: college?['short_name'] as String? ?? '');
    final descCtrl  = TextEditingController(text: college?['description'] as String? ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(college == null ? 'Add College' : 'Edit College'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'College Name')),
          const SizedBox(height: 12),
          TextField(controller: shortCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Short Name')),
          const SizedBox(height: 12),
          TextField(controller: descCtrl,
            decoration: const InputDecoration(labelText: 'Description')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _saveCollege(
                id: college?['id'] as int?,
                name: nameCtrl.text.trim(),
                shortName: shortCtrl.text.trim().toUpperCase(),
                description: descCtrl.text.trim(),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCollege({
    int? id, required String name,
    required String shortName, required String description,
  }) async {
    try {
      final auth = context.read<AuthService>();
      final api  = ApiService(sessionCookie: auth.sessionCookie);
      if (id == null) {
        await api.addCollege(name: name, shortName: shortName, description: description);
      } else {
        await api.updateCollege(id: id, name: name, shortName: shortName, description: description);
      }
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    }
  }

  Future<void> _deleteCollege(Map<String, dynamic> c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete College'),
        content: Text('Delete ${c['name']}? All programs will also be deleted.'),
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
          .deleteCollege(c['id'] as int);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    }
  }

  void _showProgramDialog({required int collegeId, Map<String, dynamic>? program}) {
    final nameCtrl     = TextEditingController(text: program?['name'] as String? ?? '');
    final durationCtrl = TextEditingController(text: program?['duration'] as String? ?? '');
    final intakeCtrl   = TextEditingController(
        text: program?['intake_capacity']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(program == null ? 'Add Program' : 'Edit Program'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Program Name')),
          const SizedBox(height: 12),
          TextField(controller: durationCtrl,
            decoration: const InputDecoration(labelText: 'Duration (e.g. 3 Years)')),
          const SizedBox(height: 12),
          TextField(controller: intakeCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Intake Capacity')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _saveProgram(
                id: program?['id'] as int?,
                collegeId: collegeId,
                name: nameCtrl.text.trim(),
                duration: durationCtrl.text.trim(),
                intake: int.tryParse(intakeCtrl.text.trim()) ?? 0,
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProgram({
    int? id, required int collegeId, required String name,
    required String duration, required int intake,
  }) async {
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
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    }
  }
}

class _CollegeCard extends StatelessWidget {
  final Map<String, dynamic> college;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddProgram;
  const _CollegeCard({
    required this.college,
    required this.onEdit,
    required this.onDelete,
    required this.onAddProgram,
  });

  @override
  Widget build(BuildContext context) {
    final programs = college['programs'] as List<dynamic>? ?? [];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(college['short_name'] as String? ?? '',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900, fontSize: 13)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(college['name'] as String? ?? '',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14))),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                  if (v == 'add_program') onAddProgram();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'add_program',
                    child: Row(children: [
                      Icon(Icons.add, size: 16, color: AppColors.success),
                      SizedBox(width: 8), Text('Add Program'),
                    ])),
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
            ]),
            if (college['description'] != null &&
                (college['description'] as String).isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(college['description'] as String,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            ],
            if (programs.isNotEmpty) ...[
              const Divider(height: 16),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: programs.map((p) => Chip(
                  label: Text(p['name'] as String? ?? '',
                    style: const TextStyle(fontSize: 11)),
                  backgroundColor: AppColors.accent.withOpacity(0.1),
                  side: BorderSide(color: AppColors.accent.withOpacity(0.3)),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
