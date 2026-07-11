import 'package:flutter/material.dart';

import '../area/area_profile_screen.dart';
import '../explore/explore_screen.dart';
import '../messages/chat_list_screen.dart';
import 'home_feed_screen.dart';

/// Persistent bottom-tab shell for the 4 first-class destinations (matching
/// the reference app's always-reachable Home/Explore/Chats/Profile tabs,
/// rather than burying Explore/Chats in a drawer). Each tab is an existing
/// screen used as-is - nested Scaffolds are normal Flutter, so
/// HomeFeedScreen/ChatListScreen/AreaProfileScreen keep their own AppBar,
/// FAB, and drawer untouched. All existing pushed routes (post detail, map,
/// emergency, society, chat threads) keep working on top of this shell.
class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _index = 0;

  static const _tabs = [
    HomeFeedScreen(),
    ExploreScreen(),
    ChatListScreen(),
    AreaProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Chats'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
