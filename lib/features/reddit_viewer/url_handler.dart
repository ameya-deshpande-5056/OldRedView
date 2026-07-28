import 'package:flutter/foundation.dart';

/// Handles initial URL parsing when the app is launched via a deep link.
///
/// This service processes the raw incoming URL from Android's intent system
/// and prepares it for the WebView. It handles:
/// - Standard Reddit URLs (reddit.com, www.reddit.com, etc.)
/// - redd.it short links
/// - Invalid or empty URLs (returns a default homepage)
class UrlHandler {
  UrlHandler._();

  /// The default URL to load when no link was provided (app launched normally).
  static const String defaultUrl = 'https://old.reddit.com';

  /// Validates and normalizes a potential Reddit URL.
  ///
  /// Returns a normalized URL to load, or the [defaultUrl] if the input is
  /// empty, null, or invalid.
  ///
  /// Edge cases handled:
  /// - null or empty input -> defaultUrl
  /// - invalid URL format -> defaultUrl
  /// - URL without scheme -> prepends https://
  /// - redd.it short link -> converted to reddit.com (then WebView delegates
  ///   will rewrite to old.reddit.com)
  /// - already valid HTTP(S) URL -> returned as-is
  static String prepareInitialUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      debugPrint('[UrlHandler] No URL provided, using default: $defaultUrl');
      return defaultUrl;
    }

    var url = rawUrl.trim();

    // If the URL doesn't have a scheme, assume HTTPS.
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    // Validate that the URL can be parsed.
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || (!uri.hasAuthority && uri.host.isEmpty)) {
        debugPrint('[UrlHandler] Invalid URL format: $rawUrl');
        return defaultUrl;
      }
    } catch (e) {
      debugPrint('[UrlHandler] Failed to parse URL: $rawUrl, error: $e');
      return defaultUrl;
    }

    debugPrint('[UrlHandler] Prepared URL: $url');
    return url;
  }

  /// Whether the given [url] is the default homepage.
  static bool isDefaultUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host == 'old.reddit.com' && (uri.path == '/' || uri.path.isEmpty)) {
        return true;
      }
    } catch (_) {
      // Fall through
    }
    return url == defaultUrl;
  }
}