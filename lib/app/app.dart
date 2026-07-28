import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/reddit_viewer/reddit_webview.dart';
import '../main.dart';
import 'theme.dart';

/// The root widget of the Old Reddit Viewer application.
///
/// This widget handles:
/// - System theme detection (light/dark mode via [ThemeMode.system]).
/// - Receiving the initial URL passed from a deep link intent.
/// - Rendering the full-screen WebView with the Reddit content.
class OldRedditApp extends StatelessWidget {
  const OldRedditApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Old Reddit Viewer',
      debugShowCheckedModeBanner: false,

      // Automatically follow the system light/dark mode.
      // No in-app theme selector is provided.
      themeMode: ThemeMode.system,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,

      home: _Home(),
    );
  }
}

/// Internal wrapper that detects the current brightness and passes it to
/// the WebView so it can inject/remove Dark Reader CSS accordingly.
///
/// Also listens for incoming deep links via [linkNotifier] and forwards
/// them to the WebView when the app is already running.
class _Home extends StatefulWidget {
  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> with WidgetsBindingObserver {
  /// The current URL being displayed in the WebView.
  /// Updated when a new deep link arrives while the app is running.
  String? _currentUrl;

  /// Whether the initial platform URL lookup has completed.
  bool _initialUrlResolved = false;

  /// A unique key that forces the WebView to rebuild when a new link arrives.
  /// This ensures the WebView navigates to the new URL even if it's the same
  /// widget instance.
  int _linkKey = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Listen for incoming deep links while the app is running.
    linkNotifier.addListener(_onLinkChanged);

    // Query the initial URL asynchronously after the widget is built.
    // This is more reliable than querying in main() because the Flutter
    // engine and plugins are fully initialized at this point.
    _queryInitialUrl();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    linkNotifier.removeListener(_onLinkChanged);
    super.dispose();
  }

  /// Queries the initial deep link URL using multiple strategies.
  ///
  /// This is called after the widget is initialized to ensure the Flutter
  /// engine and all plugins are ready. It tries:
  /// 1. Method channel to Kotlin — handles both ACTION_VIEW and ACTION_SEND
  /// 2. [AppLinks.getInitialLink] — standard app_links fallback
  /// 3. [AppLinks.getLatestLink] — fallback for some Android versions
  Future<void> _queryInitialUrl() async {
    String? url;

    // Strategy 1: Method channel. Android extracts the URL from shared text,
    // including Google and Bing redirect wrappers, before Flutter sees it.
    try {
      const channel = MethodChannel('com.example.open_in_old_reddit/intent');
      final intentUrl = await channel.invokeMethod<String>(
        'getInitialIntentUrl',
      );
      if (intentUrl != null && intentUrl.isNotEmpty) {
        url = intentUrl;
        debugPrint('[App] Initial URL (method channel): $url');
      }
    } catch (e) {
      debugPrint('[App] Method channel failed: $e');
    }

    // Strategy 2: app_links getInitialLink
    if (url == null) {
      try {
        final appLinks = AppLinks();
        final initialUri = await appLinks.getInitialLink();
        if (initialUri != null) {
          url = initialUri.toString();
          debugPrint('[App] Initial URL (getInitialLink): $url');
        }
      } catch (e) {
        debugPrint('[App] getInitialLink failed: $e');
      }
    }

    // Strategy 3: app_links getLatestLink
    if (url == null) {
      try {
        final appLinks = AppLinks();
        final latestUri = await appLinks.getLatestLink();
        if (latestUri != null) {
          url = latestUri.toString();
          debugPrint('[App] Initial URL (getLatestLink): $url');
        }
      } catch (e) {
        debugPrint('[App] getLatestLink failed: $e');
      }
    }

    if (mounted) {
      setState(() {
        _currentUrl = url;
        _initialUrlResolved = true;
        // Force the WebView to rebuild with the new URL if one was found.
        if (url != null) {
          _linkKey++;
        }
      });
    }
  }

  /// Called when a new deep link arrives via [linkNotifier].
  void _onLinkChanged() {
    final newLink = linkNotifier.value;
    if (newLink != null && newLink != _currentUrl) {
      debugPrint('[App] New deep link received: $newLink');
      if (mounted) {
        setState(() {
          _currentUrl = newLink;
          _linkKey++; // Force WebView rebuild with new URL.
        });
      }
    }
  }

  @override
  void didChangePlatformBrightness() {
    // Rebuild when system brightness changes so the WebView can
    // inject or remove the Dark Reader CSS.
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = brightness == Brightness.dark;

    if (!_initialUrlResolved) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return RedditWebView(
      key: ValueKey(_linkKey),
      initialUrl: _currentUrl,
      isDarkMode: isDarkMode,
    );
  }
}
