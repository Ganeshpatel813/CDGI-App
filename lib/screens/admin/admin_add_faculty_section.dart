import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_widgets.dart';
import '../register_screen.dart';
import 'admin_screen.dart';

class AdminAddFacultySection extends StatelessWidget {
  final VoidCallback? onDone;
  const AdminAddFacultySection({super.key, this.onDone});

  @override
  Widget build(BuildContext context) {
    return SectionPage(
      title: 'Add Faculty',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, color: Colors.white70, size: 18),
                SizedBox(width: 10),
                Expanded(child: Text(
                  'Chameli Devi Group of Institutions\n'
                  'Register a new faculty member with face recognition.',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                )),
              ]),
            ),
            const SizedBox(height: 20),

            // Steps info
            Row(children: [
              _StepChip(number: '1', label: 'Personal Info',
                  icon: Icons.person_outline),
              const SizedBox(width: 12),
              _StepChip(number: '2', label: 'Face Registration',
                  icon: Icons.face),
            ]),
            const SizedBox(height: 24),

            // Register button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const RegisterScreen(isAdminAdd: true),
                  ));
                  onDone?.call();
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Start Faculty Registration'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'The registration process will guide you through:\n'
              '• Entering personal information\n'
              '• Capturing face for biometric verification\n'
              '• Setting login credentials',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  final String number;
  final String label;
  final IconData icon;
  const _StepChip({
    required this.number,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 24, height: 24,
        decoration: const BoxDecoration(
            color: AppColors.primary, shape: BoxShape.circle),
        child: Center(child: Text(number,
            style: const TextStyle(color: Colors.white,
                fontSize: 12, fontWeight: FontWeight.w900))),
      ),
      const SizedBox(width: 8),
      Icon(icon, size: 16, color: AppColors.primary),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(
          color: AppColors.primary, fontWeight: FontWeight.w600,
          fontSize: 13)),
    ]),
  );
}
