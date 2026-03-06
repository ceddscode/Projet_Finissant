import 'package:flutter/material.dart';
import 'package:municipalgo/pages/chat_screen.dart';
import 'package:municipalgo/pages/create_page.dart';
import 'package:municipalgo/pages/profile_page.dart';
import 'package:municipalgo/pages/task_page.dart';
import 'package:municipalgo/pages/home_map_page.dart';
import 'package:municipalgo/widgets/bottom_nav.dart';
import 'package:provider/provider.dart';
import '../services/roleProvider.dart';

class RootScaffold extends StatefulWidget {
  final int initialIndex;
  const RootScaffold({super.key, this.initialIndex = 0});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}
class _RootScaffoldState extends State<RootScaffold> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  void _onCreatePressed() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = context
        .watch<RoleProvider>()
        .role;

    final middle = roleProvider == UserRole.blueCollar
        ? const ChatScreen()
        : const CreatePage();

    final pages = [
      HomeMapPage(),
      middle,
      TaskPage(),
      ProfilePage(),
    ];

    // pages are fixed to 4 slots: Home(0), Middle(1), Task(2), Profile(3)
    final safeIndex = (_currentIndex < 0 || _currentIndex >= pages.length) ? 0 : _currentIndex;

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNav(
          currentIndex: safeIndex,
          pageIndices: const [0, 1, 2, 3],
          onTabSelected: _onTabSelected,
          onCreatePressed: _onCreatePressed
      ),
    );
  }
}