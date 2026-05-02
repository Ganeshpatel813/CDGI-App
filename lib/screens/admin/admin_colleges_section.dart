export 'admin_colleges_tab.dart' show AdminCollegesTab;

import 'package:flutter/material.dart';
import 'admin_colleges_tab.dart';
import 'admin_screen.dart';

class AdminCollegesSection extends StatelessWidget {
  const AdminCollegesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionPage(
      title: 'Colleges',
      child: const AdminCollegesTab(),
    );
  }
}
