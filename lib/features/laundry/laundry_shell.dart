import 'package:flutter/material.dart';

import 'laundry_home_controller.dart';
import 'laundry_home_screen.dart';
import 'settings_screen.dart';

class LaundryShell extends StatefulWidget {
  const LaundryShell({super.key});

  @override
  State<LaundryShell> createState() => _LaundryShellState();
}

class _LaundryShellState extends State<LaundryShell> {
  late final LaundryHomeController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = LaundryHomeController();
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      LaundryHomeScreen(controller: _controller),
      SettingsScreen(controller: _controller),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}
