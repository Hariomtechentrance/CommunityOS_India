import 'package:flutter/material.dart';
import 'events_list_screen.dart';
import 'polls_list_screen.dart';
import 'posts_list_screen.dart';

class CommunityHomeScreen extends StatelessWidget {
  const CommunityHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Community'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Feed'),
              Tab(text: 'Polls'),
              Tab(text: 'Events'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            PostsListScreen(),
            PollsListScreen(),
            EventsListScreen(),
          ],
        ),
      ),
    );
  }
}
