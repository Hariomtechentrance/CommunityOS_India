import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/api_client.dart';
import '../../core/google_signin_button.dart' as gsi_button;
import '../../core/google_signin_config.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme.dart';
import 'auth_repository.dart';
import 'phone_verification.dart';

class OtpRequestScreen extends ConsumerStatefulWidget {
  const OtpRequestScreen({super.key});

  @override
  ConsumerState<OtpRequestScreen> createState() => _OtpRequestScreenState();
}

class _OtpRequestScreenState extends ConsumerState<OtpRequestScreen> {
  final _phoneController = TextEditingController(text: '+91');
  bool _loading = false;
  String? _error;

  // True once the user has signed in with Google but their Firebase account
  // has no phone number linked yet - they need to verify one to finish.
  bool _googlePending = false;
  // The Google button can only be rendered once GoogleSignIn.initialize()
  // has resolved - rendering it earlier can leave it blank/broken.
  bool _googleReady = false;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleSub;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) _initGoogleSignIn();
  }

  Future<void> _initGoogleSignIn() async {
    try {
      final signIn = GoogleSignIn.instance;
      await signIn.initialize(clientId: googleSignInWebClientId);
      _googleSub = signIn.authenticationEvents.listen(
        _handleGoogleAuthEvent,
        onError: (Object e) => setState(() => _error = e.toString()),
      );
      if (mounted) setState(() => _googleReady = true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Google sign-in unavailable: $e');
    }
  }

  Future<void> _handleGoogleAuthEvent(GoogleSignInAuthenticationEvent event) async {
    if (event is! GoogleSignInAuthenticationEventSignIn) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final googleIdToken = event.user.authentication.idToken;
      final credential = GoogleAuthProvider.credential(idToken: googleIdToken);
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseUser = userCredential.user!;

      if (firebaseUser.phoneNumber != null) {
        // Returning user who already linked a phone number previously.
        final idToken = await firebaseUser.getIdToken();
        final result = await ref.read(authRepositoryProvider).verifyFirebaseToken(idToken!);
        await ref.read(sessionControllerProvider.notifier).loginWith(
              result.accessToken,
              result.user,
            );
      } else {
        // New Google sign-in - one more step to link a phone number.
        setState(() => _googlePending = true);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Google sign-in failed');
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final phone = _phoneController.text.trim();
      final isLinking = _googlePending;
      if (kIsWeb) {
        final confirmationResult = isLinking
            ? await FirebaseAuth.instance.currentUser!.linkWithPhoneNumber(phone)
            : await FirebaseAuth.instance.signInWithPhoneNumber(phone);
        if (!mounted) return;
        context.push('/login/verify', extra: PhoneVerificationPending.web(confirmationResult));
      } else {
        // Android/iOS have no ConfirmationResult - verifyPhoneNumber reports
        // back via callbacks instead, with codeSent carrying the id needed
        // to confirm the code on the next screen.
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phone,
          verificationCompleted: (PhoneAuthCredential credential) async {
            final userCredential = isLinking
                ? await FirebaseAuth.instance.currentUser!.linkWithCredential(credential)
                : await FirebaseAuth.instance.signInWithCredential(credential);
            if (userCredential.user != null) {
              await completeFirebaseSignIn(ref, userCredential.user!);
            }
          },
          verificationFailed: (FirebaseAuthException e) {
            if (mounted) setState(() => _error = e.message ?? 'Verification failed');
          },
          codeSent: (String verificationId, int? resendToken) {
            if (!mounted) return;
            context.push(
              '/login/verify',
              extra: PhoneVerificationPending.native(verificationId, isLinking: isLinking),
            );
          },
          codeAutoRetrievalTimeout: (String verificationId) {},
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _googleSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: nikatHeroGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: nikatNavyDark.withValues(alpha: 0.3),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset('assets/images/nikat_logo.jpg', height: 72, width: 72),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'NIKAT',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800, color: nikatNavy),
                ),
                const SizedBox(height: 8),
                Text(
                  _googlePending
                      ? 'Almost done - verify your phone number to finish signing in'
                      : 'Enter your phone number to continue',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 24),
                if (!_googlePending && kIsWeb && _googleReady) ...[
                  Center(child: gsi_button.renderButton()),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('or'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    hintText: '+919876543210',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send OTP'),
                ),
              ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
