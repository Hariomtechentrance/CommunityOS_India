import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import 'phone_verification.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  final PhoneVerificationPending pending;

  const OtpVerifyScreen({super.key, required this.pending});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final code = _codeController.text.trim();
      final pending = widget.pending;
      final User firebaseUser;
      if (pending.webConfirmation != null) {
        firebaseUser = (await pending.webConfirmation!.confirm(code)).user!;
      } else {
        final credential = PhoneAuthProvider.credential(
          verificationId: pending.nativeVerificationId!,
          smsCode: code,
        );
        final userCredential = pending.isLinking
            ? await FirebaseAuth.instance.currentUser!.linkWithCredential(credential)
            : await FirebaseAuth.instance.signInWithCredential(credential);
        firebaseUser = userCredential.user!;
      }
      await completeFirebaseSignIn(ref, firebaseUser);
      // Router redirect logic takes it from here based on session state.
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Invalid or expired code');
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
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
                    Icon(Icons.mark_email_read_outlined, color: nikatOrange, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      'Verify OTP',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800, color: nikatNavy),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter the code sent to your phone',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, letterSpacing: 8),
                      decoration: const InputDecoration(
                        labelText: '6-digit code',
                        counterText: '',
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
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
                          : const Text('Verify'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              // The phone-entry screen is still on the stack
                              // with the number already filled in - popping
                              // back to it and re-tapping Send OTP is the
                              // resend flow.
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/login');
                              }
                            },
                      child: const Text("Didn't receive the code? Resend"),
                    ),
                    TextButton(
                      onPressed: _loading ? null : () => context.go('/'),
                      child: const Text('Cancel and go back to main page'),
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
