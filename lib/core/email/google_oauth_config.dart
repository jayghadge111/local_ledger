// Google OAuth client IDs for Gmail sign-in. These are public identifiers
// (not secrets) — they only tell Google which app is asking. The matching
// client *secret* is never needed or stored: sign-in runs on-device.
//
// Create them in Google Cloud Console -> Google Auth Platform -> Clients.

/// iOS client (bundle ID com.localledger.localLedger). Also set in
/// ios/Runner/Info.plist as GIDClientID, with its reversed form as a URL scheme.
const googleIosClientId =
    '781017793459-m6m4f987jl8fqhj12bkool98hlcp8u0s.apps.googleusercontent.com';

/// Android needs the ID of a *Web application* client here (not Android,
/// not Desktop) — Credential Manager uses it to identify the app to Google.
const googleServerClientId =
    '781017793459-gi9svir0nnimcpo166n8v90gb97kova9.apps.googleusercontent.com';
