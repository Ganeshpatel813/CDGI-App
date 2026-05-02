import 'package:flutter/material.dart';
import '../main.dart';

// ── Stat Card ─────────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final String? subtitle;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12), shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(
              fontSize: 11, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: const TextStyle(
                fontSize: 10, color: AppColors.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'present':  color = AppColors.success; label = 'Present';  break;
      case 'half_day': color = AppColors.warning; label = 'Half Day'; break;
      case 'absent':   color = AppColors.error;   label = 'Absent';   break;
      default:         color = AppColors.textSecondary; label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(
        color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────────────────────
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const InfoRow({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(
            color: AppColors.textSecondary, fontSize: 13)),
          const Spacer(),
          Flexible(child: Text(value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary, fontSize: 13))),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(title, style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w800,
            color: AppColors.textPrimary)),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ── Error Box ─────────────────────────────────────────────────────────────────
class ErrorBox extends StatelessWidget {
  final String message;
  const ErrorBox({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message,
            style: const TextStyle(color: AppColors.error, fontSize: 13))),
        ],
      ),
    );
  }
}

// ── Success Box ───────────────────────────────────────────────────────────────
class SuccessBox extends StatelessWidget {
  final String message;
  const SuccessBox({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message,
            style: const TextStyle(color: AppColors.success, fontSize: 13))),
        ],
      ),
    );
  }
}

// ── Loading Button ────────────────────────────────────────────────────────────
class LoadingButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;
  final String label;
  final Color? color;
  final IconData? icon;

  const LoadingButton({
    super.key,
    required this.loading,
    required this.onPressed,
    required this.label,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? AppColors.primary,
      ),
      child: loading
          ? const SizedBox(height: 20, width: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                Text(label),
              ],
            ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────
class NameAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final Color? bg;
  const NameAvatar({super.key, required this.name, this.radius = 24, this.bg});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: bg ?? AppColors.primary,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.75,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// ── Attendance Record Tile ────────────────────────────────────────────────────
class AttendanceTile extends StatelessWidget {
  final Map<String, dynamic> record;
  const AttendanceTile({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final status = record['status'] as String? ?? 'absent';
    Color color;
    IconData icon;
    switch (status) {
      case 'present':  color = AppColors.success; icon = Icons.check_circle; break;
      case 'half_day': color = AppColors.warning; icon = Icons.timelapse;    break;
      default:         color = AppColors.error;   icon = Icons.cancel;
    }
    final date = record['attendance_date'] as String? ?? '';
    final ci   = record['check_in_time']  as String?;
    final co   = record['check_out_time'] as String?;
    final hrs  = (record['working_hours'] as num?)?.toDouble();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date, style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 3),
                  Row(children: [
                    if (ci != null) ...[
                      const Icon(Icons.login, size: 12, color: AppColors.success),
                      const SizedBox(width: 2),
                      Text(_fmt(ci), style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                    ],
                    if (co != null) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.logout, size: 12, color: AppColors.error),
                      const SizedBox(width: 2),
                      Text(_fmt(co), style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ]),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(status: status),
                if (hrs != null) ...[
                  const SizedBox(height: 4),
                  Text('${hrs.toStringAsFixed(1)}h',
                    style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(String t) => t.length >= 5 ? t.substring(0, 5) : t;
}
