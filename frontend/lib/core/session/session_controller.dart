import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/auth_repository.dart';
import '../../features/membership/membership_repository.dart';
import '../../features/societies/society_repository.dart';
import '../../features/users/user_repository.dart';
import '../../models/membership.dart';
import '../../models/society.dart';
import '../../models/user.dart';
import '../api_client.dart';
import 'session_storage.dart';

class SessionState {
  final String? token;
  final AppUser? user;
  final Society? society;
  final Membership? membership;

  const SessionState({this.token, this.user, this.society, this.membership});

  bool get isAuthenticated => token != null && user != null;
  bool get isSuperAdmin => user?.isSuperAdmin ?? false;
  bool get hasLocationProfile => user?.hasLocationProfile ?? false;
  bool get hasSociety => society != null;
  bool get isApproved => membership?.status == MembershipStatus.approved;
  bool get isPending => membership?.status == MembershipStatus.pending;

  SessionState copyWith({
    String? token,
    AppUser? user,
    Society? society,
    Membership? membership,
    bool clearSociety = false,
    bool clearMembership = false,
  }) {
    return SessionState(
      token: token ?? this.token,
      user: user ?? this.user,
      society: clearSociety ? null : (society ?? this.society),
      membership: clearMembership ? null : (membership ?? this.membership),
    );
  }
}

class SessionController extends AsyncNotifier<SessionState> {
  final _storage = SessionStorage();

  @override
  Future<SessionState> build() async {
    final token = await _storage.readToken();
    if (token == null) return const SessionState();

    ref.read(apiClientProvider).token = token;

    // Prefer a fresh /users/me (picks up location profile changes made
    // elsewhere); fall back to the cached copy if that fails (e.g. offline).
    AppUser? user;
    try {
      user = await ref.read(userRepositoryProvider).getMe();
      await _storage.writeUser(user.toJson());
    } catch (_) {
      final userJson = await _storage.readUser();
      user = userJson != null ? AppUser.fromJson(userJson) : null;
    }

    if (user == null) {
      await _storage.clear();
      return const SessionState();
    }

    var state = SessionState(token: token, user: user);

    final societyId = await _storage.readSocietyId();
    if (societyId == null) return state;

    try {
      final society = await ref.read(societyRepositoryProvider).getById(societyId);
      final membership = await ref.read(membershipRepositoryProvider).findMine(societyId);
      state = state.copyWith(society: society, membership: membership);
    } catch (_) {
      await _storage.writeSocietyId(null);
    }

    return state;
  }

  Future<void> loginWith(String token, AppUser user) async {
    ref.read(apiClientProvider).token = token;
    await _storage.writeToken(token);
    await _storage.writeUser(user.toJson());
    state = AsyncData(SessionState(token: token, user: user));
  }

  /// Logs into the shared, pre-seeded Demo Society as a fresh Committee Admin
  /// in one step - no login/Firebase required. Reuses [loginWith] + the same
  /// storage as a real session, so every guard/screen treats it identically.
  Future<void> loginAsDemo() async {
    final result = await ref.read(authRepositoryProvider).loginAsDemo();
    await loginWith(result.accessToken, result.user);
    await _storage.writeSocietyId(result.society.id);
    final current = state.value ?? const SessionState();
    state = AsyncData(current.copyWith(society: result.society, membership: result.membership));
  }

  /// Called after the location-onboarding form is submitted.
  Future<void> refreshUser() async {
    final user = await ref.read(userRepositoryProvider).getMe();
    await _storage.writeUser(user.toJson());
    final current = state.value ?? const SessionState();
    state = AsyncData(current.copyWith(user: user));
  }

  Future<void> selectSociety(Society society, Membership? membership) async {
    await _storage.writeSocietyId(society.id);
    final current = state.value ?? const SessionState();
    state = AsyncData(
      current.copyWith(
        society: society,
        membership: membership,
        clearMembership: membership == null,
      ),
    );
  }

  Future<void> refreshMembership() async {
    final current = state.value;
    if (current?.society == null) return;
    final membership =
        await ref.read(membershipRepositoryProvider).findMine(current!.society!.id);
    state = AsyncData(
      current.copyWith(membership: membership, clearMembership: membership == null),
    );
  }

  Future<void> leaveSociety() async {
    await _storage.writeSocietyId(null);
    final current = state.value ?? const SessionState();
    state = AsyncData(
      SessionState(token: current.token, user: current.user, society: null, membership: null),
    );
  }

  Future<void> logout() async {
    ref.read(apiClientProvider).token = null;
    await _storage.clear();
    state = const AsyncData(SessionState());
  }
}

final sessionControllerProvider = AsyncNotifierProvider<SessionController, SessionState>(
  SessionController.new,
);
