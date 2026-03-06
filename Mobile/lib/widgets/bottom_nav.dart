import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/roleProvider.dart';
import '../services/chat_notifier.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onCreatePressed;
  final List<int> pageIndices;
  final int unreadCount;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onCreatePressed,
    required this.pageIndices,
    this.unreadCount = 0
  });

  @override
  Widget build(BuildContext context) {
    final roleProvider = context.watch<RoleProvider>().role;

    if (roleProvider == UserRole.unknown) {
      return BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Center(child: _buildSmallIcon(context, Icons.home, pageIndices[0]))),
            const SizedBox(width: 80),
            Expanded(child: Center(child: _buildSmallIcon(context, Icons.location_on_outlined, pageIndices[1])),),
          ],
        ),
      );
    }

    final homeIdx = pageIndices[0];
    final createIdx = pageIndices[1];
    final taskIdx = pageIndices[2];
    final profileIdx = pageIndices[3];
    final role = context.watch<RoleProvider>().role;

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Home
            _NavButton(icon: Icons.home_outlined, active: currentIndex == homeIdx, onTap: () => onTabSelected(homeIdx)),

            // Create / Report or Chat (depends on role)
            if (role == UserRole.blueCollar)
              ListenableBuilder(
                listenable: chatNotifier,
                builder: (_, __) => GestureDetector(
                  onTap: () => onTabSelected(createIdx),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Badge(
                        isLabelVisible: chatNotifier.unreadCount > 0,
                        label: Text('${chatNotifier.unreadCount}',
                            style: const TextStyle(fontSize: 10)),
                        backgroundColor: Colors.red,
                        child: Icon(
                          Icons.chat_bubble_outline,
                          color: currentIndex == createIdx
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[600],
                          size: currentIndex == createIdx ? 28 : 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (currentIndex == createIdx)
                        Container(
                          width: 20, height: 3,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                ),
              )
            else
              _NavButton(
                icon: Icons.add_box_outlined,
                active: currentIndex == createIdx,
                onTap: () => onTabSelected(createIdx),
              ),



            // Tasks
            _NavButton(icon: Icons.assignment_outlined, active: currentIndex == taskIdx, onTap: () => onTabSelected(taskIdx)),

            // Profile
            _NavButton(icon: Icons.person_outline, active: currentIndex == profileIdx, onTap: () => onTabSelected(profileIdx)),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallIcon(BuildContext context, IconData icon, int index) {
    return IconButton(
      onPressed: () => onTabSelected(index),
      icon: Icon(icon, color: Colors.grey),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final int badge;

  const _NavButton({required this.icon, required this.active, required this.onTap, this.badge = 0,});

  @override
  Widget build(BuildContext context) {
    final color = active ? Theme.of(context).colorScheme.primary : Colors.grey[600];
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Badge(
            isLabelVisible: badge > 0,
            label: Text('$badge', style: const TextStyle(fontSize: 10)),
            child: Icon(icon, color: color, size: active ? 28 : 24),
          ),
          const SizedBox(height: 4),
          if (active)
            Container(
              width: 20,
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            )
        ],
      ),
    );
  }
}
