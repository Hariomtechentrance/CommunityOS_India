import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../area/area_profile_screen.dart';
import '../explore/explore_screen.dart';
import '../messages/chat_list_screen.dart';
import '../reels/reels_feed_screen.dart';
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
    ReelsFeedScreen(),
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
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: AppLocalizations.of(context)!.navHome),
          NavigationDestination(icon: const Icon(Icons.explore_outlined), selectedIcon: const Icon(Icons.explore), label: AppLocalizations.of(context)!.navExplore),
          NavigationDestination(icon: const Icon(Icons.play_circle_outline), selectedIcon: const Icon(Icons.play_circle), label: AppLocalizations.of(context)!.navReels),
          NavigationDestination(icon: const Icon(Icons.chat_bubble_outline), selectedIcon: const Icon(Icons.chat_bubble), label: AppLocalizations.of(context)!.navChats),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: AppLocalizations.of(context)!.navProfile),
        ],
      ),
    );
  }
}
