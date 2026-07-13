import 'api_client.dart';

/// Fetches ICE servers (STUN + TURN relay) for WebRTC peer connections.
/// Falls back to Google's public STUN-only server if the backend call fails
/// for any reason - same-network calls/streams keep working either way,
/// only cross-network relay is lost.
Future<List<Map<String, dynamic>>> fetchIceServers(ApiClient client) async {
  const fallback = [
    {'urls': 'stun:stun.l.google.com:19302'},
  ];
  try {
    final res = await client.dio.get('/turn-credentials');
    final iceServers = res.data['iceServers'] as List;
    return iceServers.cast<Map<String, dynamic>>();
  } catch (_) {
    return fallback;
  }
}
