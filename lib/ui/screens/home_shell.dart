import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import 'dashboard_screen.dart';
import 'analytics_screen.dart';
import 'history_screen.dart';
import 'doctor_report_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    AnalyticsScreen(),
    HistoryScreen(),
    DoctorReportScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primaryLight,
          elevation: 0,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home, color: AppColors.primary),
              label: l10n.navDashboard,
            ),
            NavigationDestination(
              icon: const Icon(Icons.show_chart_outlined),
              selectedIcon: const Icon(Icons.show_chart, color: AppColors.primary),
              label: l10n.navTrends,
            ),
            NavigationDestination(
              icon: const Icon(Icons.history_outlined),
              selectedIcon: const Icon(Icons.history, color: AppColors.primary),
              label: l10n.navHistory,
            ),
            NavigationDestination(
              icon: const Icon(Icons.medical_services_outlined),
              selectedIcon: const Icon(Icons.medical_services, color: AppColors.primary),
              label: l10n.navDoctorPdf,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings, color: AppColors.primary),
              label: l10n.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}
