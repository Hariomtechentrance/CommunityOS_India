// From Firebase Console -> Project Settings (gear icon) -> Cloud Messaging
// tab -> Web configuration -> generate a Web Push certificate (VAPID key
// pair) -> paste the public key here. Not a secret (same visibility as the
// Maps browser key), but push registration silently fails until it's real.
const vapidKey = 'REPLACE_WITH_VAPID_KEY';
