import 'dart:io' show Platform;

import 'package:google_sign_in/google_sign_in.dart';

import 'google_oauth_config.dart';

/// Wraps `google_sign_in` for the one thing this app needs: read-only
/// access to the signed-in user's own Gmail inbox, authenticated directly
/// against Google — never through any server of ours.
///
/// Requires OAuth client credentials configured in the Google Cloud
/// Console (see the README note on email setup) — without them,
/// [signIn] throws a [GoogleSignInException] at the native layer.
class GmailAuthService {
  static const scopes = ['https://www.googleapis.com/auth/gmail.readonly'];

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      clientId: Platform.isIOS ? googleIosClientId : null,
      serverClientId: Platform.isAndroid ? googleServerClientId : null,
    );
    _initialized = true;
  }

  Future<GoogleSignInAccount> signIn() async {
    await _ensureInitialized();
    final account = await GoogleSignIn.instance.authenticate();
    await account.authorizationClient.authorizeScopes(scopes);
    return account;
  }

  Future<GoogleSignInAccount?> currentAccount() async {
    await _ensureInitialized();
    return GoogleSignIn.instance.attemptLightweightAuthentication();
  }

  /// Bearer-token header for direct Gmail REST calls, re-prompting for
  /// consent if needed.
  Future<Map<String, String>> authHeaders(GoogleSignInAccount account) async {
    final headers = await account.authorizationClient.authorizationHeaders(
      scopes,
      promptIfNecessary: true,
    );
    if (headers == null) {
      throw StateError('Gmail authorization was not granted');
    }
    return headers;
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    await GoogleSignIn.instance.signOut();
  }
}
