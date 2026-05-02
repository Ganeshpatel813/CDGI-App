// Faculty Management — same as All Faculty but with edit capability
export 'admin_all_faculty_section.dart' show AdminAllFacultySection;

import 'package:flutter/material.dart';
import 'admin_all_faculty_section.dart';
import 'admin_screen.dart';

class AdminFacultyMgmtSection extends StatelessWidget {
  const AdminFacultyMgmtSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionPage(
      title: 'Faculty Management',
      child: const AdminAllFacultySection(),
    );
  }
}
