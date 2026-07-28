import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';

/// A notifier that broadcasts incoming Reddit deep links to the app.
///
/// This is used to forward links that arrive while the app is already running
/// (e.g., from Google Search or other apps) to the WebView.
final ValueNotifier<String?> linkNotifier = ValueNotifier<String?>(null);

/// The entry point for the Old Reddit Viewer application.
///
/// The app registers as a handler for Reddit URLs on Android. When launched
/// via a deep link, the incoming URL is passed to [OldRedditApp] which
/// converts it to an old.reddit.com equivalent and displays it in the WebView.
///
/// If the app is launched normally (without a Reddit URL), the default
/// old.reddit.com homepage is shown.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Subscribe to the ongoing link stream for links that arrive while
  // the app is already running (e.g., from Google Search, share sheet).
  _subscribeToLinkStream();
  _subscribeToSharedIntentChannel();

  runApp(OldRedditApp());
}

/// Receives URLs from Android share intents. The app_links plugin handles
/// ACTION_VIEW but does not receive ACTION_SEND consistently.
void _subscribeToSharedIntentChannel() {
  const channel = MethodChannel('com.example.open_in_old_reddit/intent');
  channel.setMethodCallHandler((call) async {
    if (call.method != 'onIntentUrl') return;

    final url = call.arguments as String?;
    if (url != null && url.isNotEmpty) {
      debugPrint('[Main] Shared URL received: $url');
      linkNotifier.value = url;
    }
  });
}

/// Subscribes to the [AppLinks.uriLinkStream] to capture links that arrive
/// while the app is already running.
///
/// When a new Reddit URL is received (e.g., user opens a Reddit link from
/// Google Search while the app is in the background), this forwards it to
/// the [linkNotifier] which the WebView widget listens to.
void _subscribeToLinkStream() {
  try {
    final appLinks = AppLinks();

    // Listen for links arriving while the app is running.
    appLinks.uriLinkStream
        .listen((Uri? uri) {
          if (uri != null) {
            debugPrint('[Main] Link received via stream: $uri');
            linkNotifier.value = uri.toString();
          }
        })
        .onError((Object error) {
          debugPrint('[Main] Link stream error: $error');
        });
  } catch (e) {
    debugPrint('[Main] Failed to subscribe to link stream: $e');
  }
}
