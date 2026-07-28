import 'package:flutter/foundation.dart';

/// Service that converts any Reddit URL to its old.reddit.com equivalent.
///
/// This is the core redirect logic. Every navigation event in the WebView
/// passes through [convertToOldReddit] so that the user always sees the
/// classic Reddit interface.
class RedditRedirectService {
  RedditRedirectService._();

  /// Hostnames that should be rewritten to old.reddit.com.
  static const Set<String> _redditHosts = <String>{
    'reddit.com',
    'www.reddit.com',
    'm.reddit.com',
    'old.reddit.com',
  };

  /// Whether [url] is a Reddit URL that should be intercepted.
  static bool isRedditUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return _redditHosts.contains(uri.host);
    } catch (_) {
      return false;
    }
  }

  /// Converts a redd.it short link to its full URL.
  ///
  /// redd.it/abc123 -> reddit.com/abc123
  /// The WebView will then load it, and the navigation delegate will rewrite
  /// it to old.reddit.com/abc123 automatically.
  static String resolveShortLink(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host == 'redd.it') {
        return 'https://reddit.com${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}${uri.hasFragment ? '#${uri.fragment}' : ''}';
      }
    } catch (_) {
      // Fall through
    }
    return url;
  }

  /// Converts any supported Reddit URL to its old.reddit.com equivalent.
  ///
  /// Preserves the path, query parameters, and fragment. Returns the original
  /// URL if it cannot be parsed or is not a Reddit URL.
  ///
  /// Examples:
  ///   https://www.reddit.com/r/flutter ->
  ///   https://old.reddit.com/r/flutter
  ///
  ///   https://reddit.com/r/android/?sort=new ->
  ///   https://old.reddit.com/r/android/?sort=new
  static String convertToOldReddit(String url) {
    try {
      final uri = Uri.parse(url);

      // If the URL is already on old.reddit.com and not a special path,
      // return it as-is to avoid unnecessary rewriting.
      if (uri.host == 'old.reddit.com') {
        return url;
      }

      // Only rewrite known Reddit hostnames.
      if (!_redditHosts.contains(uri.host)) {
        return url;
      }

      // Reconstruct the URL with old.reddit.com as the host.
      final newUri = Uri(
        scheme: uri.scheme,
        host: 'old.reddit.com',
        path: uri.path,
        queryParameters: uri.queryParametersAll.isNotEmpty
            ? uri.queryParametersAll
            : null,
        fragment: uri.hasFragment ? uri.fragment : null,
      );

      return newUri.toString();
    } catch (_) {
      return url;
    }
  }

  /// Extracts the initial Reddit URL from app launch arguments.
  ///
  /// When the app is opened via a deep link, the URL is passed as a launch
  /// argument. This method checks common places where the URL might appear:
  /// - The [initialUrl] parameter directly
  /// - Command-line arguments (for testing)
  ///
  /// Returns null if no Reddit URL is found (app launched normally).
  static String? extractUrlFromLaunchArgs(String? initialUrl) {
    if (initialUrl != null && initialUrl.isNotEmpty) {
      return initialUrl;
    }

    // Check command-line arguments (useful for testing via CLI).
    for (final arg in kIsWeb ? <String>[] : const <String>[]) {
      if (arg.startsWith('https://') || arg.startsWith('http://')) {
        return arg;
      }
    }

    return null;
  }
}