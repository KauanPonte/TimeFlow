import 'dart:io';

Future<bool> hasInternetAccess() async {
  const timeout = Duration(seconds: 3);
  const host = 'firestore.googleapis.com';

  try {
    final lookup = await InternetAddress.lookup(host).timeout(timeout);
    if (lookup.isEmpty) return false;
  } catch (_) {}

  try {
    final socket = await Socket.connect(host, 443, timeout: timeout);
    socket.destroy();
    return true;
  } catch (_) {}

  return false;
}
