import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session/session_controller.dart';
import 'auth_repository.dart';

/// Carries whatever Firebase gives back from starting phone verification -
/// a [ConfirmationResult] on web, or a raw verificationId on Android/iOS,
/// since `signInWithPhoneNumber`/`ConfirmationResult` are web-only APIs and
/// mobile instead uses the callback-based `verifyPhoneNumber`.
class PhoneVerificationPending {
  final ConfirmationResult? webConfirmation;
  final String? nativeVerificationId;
  final bool isLinking;

  const PhoneVerificationPending.web(ConfirmationResult confirmation)
      : webConfirmation = confirmation,
        nativeVerificationId = null,
        isLinking = false;

  const PhoneVerificationPending.native(String verificationId, {required this.isLinking})
      : webConfirmation = null,
        nativeVerificationId = verificationId;
}

Future<void> completeFirebaseSignIn(WidgetRef ref, User firebaseUser) async {
  // Force a fresh token: right after linking a new credential (e.g. phone
  // linked onto a Google account), a cached token can still predate the
  // link and miss the phone_number claim the backend requires.
  final idToken = await firebaseUser.getIdToken(true);
  final result = await ref.read(authRepositoryProvider).verifyFirebaseToken(idToken!);
  await ref.read(sessionControllerProvider.notifier).loginWith(result.accessToken, result.user);
}
