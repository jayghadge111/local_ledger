import 'dart:io' show Platform;

import 'package:google_sign_in/google_sign_in.dart';

import 'google_oauth_config.dart';

/// Google refused the saved sign-in: access was revoked, or the token expired
/// and couldn't be renewed. The user has to connect again; nothing is wrong
/// with the app. A paused import keeps its checkpoint and can resume then.
class GmailAccessException implements Exception {
  const GmailAccessException([this.detail]);
  final String? detail;

  @override
  String toString() => 'Gmail access was refused${detail == null ? '' : ' ($detail)'}';
}

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

  /// An explicit "Connect" / "Switch account": signs out first so Google
  /// always shows its account chooser (and its consent screen, unless this
  /// account already approved the app) instead of silently reusing the last
  /// account.
  Future<GoogleSignInAccount> signInFresh() async {
    await _ensureInitialized();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    return signIn();
  }

  /// Signs out AND revokes the app's access at Google, so the next connect
  /// asks for consent again.
  Future<void> disconnect() async {
    await _ensureInitialized();
    await GoogleSignIn.instance.disconnect();
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
      throw const GmailAccessException('authorization was not granted');
    }
    return headers;
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    await GoogleSignIn.instance.signOut();
  }
}
