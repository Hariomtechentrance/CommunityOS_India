import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/session/session_controller.dart';
import 'features/admin/admin_dashboard_screen.dart';
import 'features/admin/admin_login_screen.dart';
import 'features/admin/admin_user_detail_screen.dart';
import 'features/admin/admin_users_list_screen.dart';
import 'features/area/area_post_detail_screen.dart';
import 'features/area/area_profile_screen.dart';
import 'features/area/saved_posts_screen.dart';
import 'features/auth/demo_user_switcher_screen.dart';
import 'features/auth/otp_request_screen.dart';
import 'features/auth/otp_verify_screen.dart';
import 'features/auth/phone_verification.dart';
import 'features/community/community_home_screen.dart';
import 'features/community/event_detail_screen.dart';
import 'features/community/post_detail_screen.dart';
import 'features/complaints/complaints_list_screen.dart';
import 'features/emergency/emergency_sos_screen.dart';
import 'features/explore/explore_map_screen.dart';
import 'features/home/home_map_screen.dart';
import 'features/home/home_shell_screen.dart';
import 'features/home/society_home_screen.dart';
import 'features/landing/landing_screen.dart';
import 'features/marketplace/listing_detail_screen.dart';
import 'features/marketplace/listings_list_screen.dart';
import 'features/membership/join_society_screen.dart';
import 'features/membership/manage_members_screen.dart';
import 'features/membership/pending_approval_screen.dart';
import 'features/messages/chat_list_screen.dart';
import 'features/messages/chat_screen.dart';
import 'features/notices/notices_list_screen.dart';
import 'features/onboarding/location_setup_screen.dart';
import 'features/societies/create_society_screen.dart';
import 'features/societies/society_search_screen.dart';
import 'features/users/follow_list_screen.dart';
import 'features/users/public_profile_screen.dart';
import 'features/users/user_search_screen.dart';
import 'models/society.dart';

/// Bridges Riverpod's [sessionControllerProvider] to go_router's
/// [Listenable]-based `refreshListenable`, so navigation redirects re-run
/// whenever the session state changes (login, location saved, society
/// selected, approved...).
class _SessionRefreshListenable extends ChangeNotifier {
  _SessionRefreshListenable(Ref ref) {
    ref.listen(sessionControllerProvider, (_, _) => notifyListeners());
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// Rendered instead of [JoinSocietyScreen] when `extra` comes back null (see
/// the `/societies/join` route below). Actively bounces to `/home` on the
/// next frame rather than just rendering blank and leaving the user stranded
/// on a dead page.
class _StaleJoinFallback extends StatefulWidget {
  const _StaleJoinFallback();

  @override
  State<_StaleJoinFallback> createState() => _StaleJoinFallbackState();
}

class _StaleJoinFallbackState extends State<_StaleJoinFallback> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/home');
    });
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _SessionRefreshListenable(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final asyncSession = ref.read(sessionControllerProvider);
      final location = state.matchedLocation;

      if (asyncSession.isLoading) {
        return location == '/splash' ? null : '/splash';
      }

      final session = asyncSession.value;
      final onAdmin = location.startsWith('/admin');
      final onAdminLogin = location == '/admin/login';
      final onPublicEntry = location == '/' || location.startsWith('/login');

      // Everything requires a login now - OTP verifies identity, then a
      // one-time location profile unlocks the rest of the app. /admin/login
      // is the one other unauthenticated entry point; other /admin/* paths
      // bounce there instead of rendering with no session.
      if (session == null || !session.isAuthenticated) {
        if (onPublicEntry || onAdminLogin) return null;
        return onAdmin ? '/admin/login' : '/';
      }

      // Super admins are a separate identity from consumer/society accounts
      // - no location profile, no society membership, just the admin panel.
      if (session.isSuperAdmin) {
        return onAdmin && !onAdminLogin ? null : '/admin';
      }
      if (onAdmin) {
        return '/home';
      }

      final onOnboarding = location == '/onboarding/location';

      if (!session.hasLocationProfile) {
        return onOnboarding ? null : '/onboarding/location';
      }

      if (onPublicEntry || location == '/splash' || onOnboarding) {
        return '/home';
      }

      // Society Management is an optional path reached from the map home's
      // drawer, not the mandatory gate it used to be - but once a user
      // dives into it, the existing membership rules still apply.
      final onSocietyFlow = location.startsWith('/societies');
      final onPending = location == '/pending';
      final onSocietyHome = location.startsWith('/home/society');

      if (onSocietyFlow || onPending || onSocietyHome) {
        if (!session.hasSociety) {
          return onSocietyFlow ? null : '/societies/search';
        }
        if (!session.isApproved) {
          return onPending ? null : '/pending';
        }
        if (onSocietyFlow || onPending) return '/home/society';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const _SplashScreen()),
      GoRoute(path: '/', builder: (context, state) => const LandingScreen()),
      GoRoute(path: '/login', builder: (context, state) => const OtpRequestScreen()),
      GoRoute(
        path: '/login/verify',
        builder: (context, state) =>
            OtpVerifyScreen(pending: state.extra as PhoneVerificationPending),
      ),
      GoRoute(
        path: '/login/switch-demo',
        builder: (context, state) => const DemoUserSwitcherScreen(),
      ),
      GoRoute(
        path: '/onboarding/location',
        builder: (context, state) => const LocationSetupScreen(),
      ),
      GoRoute(
        path: '/societies/search',
        builder: (context, state) => const SocietySearchScreen(),
      ),
      GoRoute(
        path: '/societies/create',
        builder: (context, state) => const CreateSocietyScreen(),
      ),
      GoRoute(
        path: '/societies/join',
        // `extra` is an in-memory value only - it doesn't survive a browser
        // reload, and go_router can also rebuild this page directly (without
        // re-running `redirect`) when an ancestor's refreshListenable fires
        // while this route is still sitting in the Navigator's page stack -
        // e.g. right after a join request gets approved. In that case
        // `extra` comes back null; render nothing rather than crash instead
        // of trying to redirect, since the stack is about to be replaced
        // anyway once the root redirect finishes reconciling.
        redirect: (context, state) => state.extra == null ? '/societies/search' : null,
        builder: (context, state) {
          final society = state.extra as Society?;
          if (society == null) return const _StaleJoinFallback();
          return JoinSocietyScreen(society: society);
        },
      ),
      GoRoute(path: '/pending', builder: (context, state) => const PendingApprovalScreen()),
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'users',
            builder: (context, state) => const AdminUsersListScreen(),
            routes: [
              GoRoute(
                path: ':userId',
                builder: (context, state) =>
                    AdminUserDetailScreen(userId: state.pathParameters['userId']!),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeShellScreen(),
        routes: [
          GoRoute(path: 'map', builder: (context, state) => const HomeMapScreen()),
          GoRoute(path: 'explore-map', builder: (context, state) => const ExploreMapScreen()),
          GoRoute(path: 'saved', builder: (context, state) => const SavedPostsScreen()),
          GoRoute(path: 'search-people', builder: (context, state) => const UserSearchScreen()),
          GoRoute(
            path: 'emergency/new',
            builder: (context, state) => const EmergencySosScreen(),
          ),
          GoRoute(
            path: 'profile',
            builder: (context, state) => const AreaProfileScreen(),
            routes: [
              GoRoute(
                path: 'edit-location',
                builder: (context, state) => const LocationSetupScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'posts/:postId',
            builder: (context, state) =>
                AreaPostDetailScreen(postId: state.pathParameters['postId']!),
          ),
          GoRoute(
            path: 'users/:userId',
            builder: (context, state) =>
                PublicProfileScreen(userId: state.pathParameters['userId']!),
            routes: [
              GoRoute(
                path: 'followers',
                builder: (context, state) => FollowListScreen(
                  userId: state.pathParameters['userId']!,
                  mode: FollowListMode.followers,
                ),
              ),
              GoRoute(
                path: 'following',
                builder: (context, state) => FollowListScreen(
                  userId: state.pathParameters['userId']!,
                  mode: FollowListMode.following,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'messages',
            builder: (context, state) => const ChatListScreen(),
            routes: [
              GoRoute(
                path: ':userId',
                builder: (context, state) => ChatScreen(
                  otherUserId: state.pathParameters['userId']!,
                  otherUserName: state.extra as String?,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'society',
            builder: (context, state) => const SocietyHomeScreen(),
            routes: [
              GoRoute(
                path: 'community',
                builder: (context, state) => const CommunityHomeScreen(),
                routes: [
                  GoRoute(
                    path: 'posts/:postId',
                    builder: (context, state) =>
                        PostDetailScreen(postId: state.pathParameters['postId']!),
                  ),
                  GoRoute(
                    path: 'events/:eventId',
                    builder: (context, state) =>
                        EventDetailScreen(eventId: state.pathParameters['eventId']!),
                  ),
                ],
              ),
              GoRoute(
                path: 'marketplace',
                builder: (context, state) => const ListingsListScreen(),
                routes: [
                  GoRoute(
                    path: ':listingId',
                    builder: (context, state) =>
                        ListingDetailScreen(listingId: state.pathParameters['listingId']!),
                  ),
                ],
              ),
              GoRoute(
                path: 'notices',
                builder: (context, state) => const NoticesListScreen(),
              ),
              GoRoute(
                path: 'complaints',
                builder: (context, state) => const ComplaintsListScreen(),
              ),
              GoRoute(
                path: 'members',
                builder: (context, state) => const ManageMembersScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
