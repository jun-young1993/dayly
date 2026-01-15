import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // if (!snapshot.hasData) {
        return SignInScreen(
          actions: [
            ForgotPasswordAction((context, email) {}),
            VerifyPhoneAction((context, _) {}),
            AuthStateChangeAction((context, state) {}),
            EmailLinkSignInAction((context) {})
          ],
          subtitleBuilder: (context, action) {
            final actionText = switch (action) {
              AuthAction.signIn => 'Please sign in to continue.',
              AuthAction.signUp => 'Please create an account to continue',
              _ => throw Exception('Invalid action: $action'),
            };

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Welcome to Firebase UI! $actionText.'),
            );
          },
          // Modify from here...
          headerBuilder: (context, constraints, shrinkOffset) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.asset('assets/images/flutterfire_logo.png'),
              ),
            );
          },
        ); // To here.
        // }

        return child;
      },
    );
  }
}
