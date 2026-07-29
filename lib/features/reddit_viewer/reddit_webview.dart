import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../services/reddit_redirect_service.dart';
import 'dark_reader_css.dart';
import 'mobile_layout_css.dart';
import 'url_handler.dart';

/// The main WebView widget that displays old.reddit.com.
///
/// This widget handles:
/// - Loading the initial Reddit URL (from deep link or default homepage).
/// - Intercepting all navigation requests to rewrite URLs to old.reddit.com.
/// - Injecting Dark Reader CSS when the device is in dark mode.
/// - Showing a loading progress indicator.
/// - Handling navigation history via the system back button.
/// - Graceful error handling with a retry button.
class RedditWebView extends StatefulWidget {
  /// The initial URL to load. If null, the default Reddit homepage is used.
  final String? initialUrl;

  /// Whether the device is currently in dark mode.
  final bool isDarkMode;

  const RedditWebView({
    super.key,
    this.initialUrl,
    required this.isDarkMode,
  });

  @override
  State<RedditWebView> createState() => _RedditWebViewState();
}

class _RedditWebViewState extends State<RedditWebView> {
  /// The WebView controller used to control navigation and execute JavaScript.
  late final WebViewController _controller;

  /// Current page load progress (0.0 to 1.0).
  double _loadingProgress = 0.0;

  /// Whether the current page failed to load.
  bool _hasError = false;

  /// The URL that failed to load (for retry).
  String? _failedUrl;

  /// Whether the dark mode CSS has been injected for the current page.
  bool _darkModeInjected = false;

  /// Whether the current layout should use phone-specific CSS.
  bool _isPhoneLayout = false;

  /// Whether the phone-specific CSS has been injected for the current page.
  bool _mobileLayoutInjected = false;

  /// Whether the current page has finished loading.
  bool _pageLoaded = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  /// Initializes the WebViewController with all required settings.
  void _initWebView() {
    // Prepare the initial URL (handle null, empty, invalid, short links).
    final preparedUrl = UrlHandler.prepareInitialUrl(widget.initialUrl);
    final resolvedUrl = RedditRedirectService.resolveShortLink(preparedUrl);
    final oldRedditUrl = RedditRedirectService.convertToOldReddit(resolvedUrl);

    debugPrint('[RedditWebView] Initial URL: $oldRedditUrl');

    _controller = WebViewController()
      // Enable JavaScript (required for Reddit functionality).
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // Allow all content (no restrictions on what can be loaded).
      ..setNavigationDelegate(
        NavigationDelegate(
          // Intercept every navigation to rewrite URLs to old.reddit.com.
          onNavigationRequest: _onNavigationRequest,
          // Track page load progress for the loading indicator.
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress / 100.0;
                _hasError = false;
              });
            }
          },
          // Called when a page finishes loading.
          onPageFinished: (String url) {
            debugPrint('[RedditWebView] Page loaded: $url');
            if (mounted) {
              setState(() {
                _loadingProgress = 1.0;
                _hasError = false;
                _pageLoaded = true;
              });
            }
            // Inject phone-only layout fixes after every page load.
            _injectMobileLayoutCss();
            // Inject dark mode CSS after every page load.
            _injectDarkModeCss();
          },
          // Handle page load failures gracefully.
          onWebResourceError: (WebResourceError error) {
            debugPrint(
              '[RedditWebView] Error loading: ${error.description} '
              '(code: ${error.errorCode})',
            );
            if (mounted) {
              setState(() {
                _hasError = true;
                _loadingProgress = 0.0;
              });
            }
            // Capture the failed URL asynchronously.
            _controller.currentUrl().then((url) {
              if (mounted) {
                setState(() {
                  _failedUrl = url;
                });
              }
            });
          },
        ),
      )
      // Enable cookies and session handling for login support.
      ..loadRequest(
        Uri.parse(oldRedditUrl),
      );
  }

  /// Intercepts navigation requests and rewrites Reddit URLs to old.reddit.com.
  ///
  /// This is the core redirect mechanism. Every time the WebView tries to
  /// navigate to a new URL, this delegate checks if it's a Reddit URL and
  /// rewrites it to the old.reddit.com equivalent.
  ///
  /// This prevents Reddit from redirecting back to the modern redesign.
  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    final url = request.url;

    // Resolve redd.it short links first.
    final resolved = RedditRedirectService.resolveShortLink(url);

    // Convert to old.reddit.com if applicable.
    final oldUrl = RedditRedirectService.convertToOldReddit(resolved);

    if (oldUrl != url) {
      debugPrint('[RedditWebView] Redirecting: $url -> $oldUrl');
      _controller.loadRequest(Uri.parse(oldUrl));
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  /// Injects the Dark Reader CSS into the WebView if dark mode is active.
  ///
  /// This is called after every page load. The CSS is injected via JavaScript
  /// by creating a <style> element and appending it to the document head.
  /// When switching back to light mode, the CSS is removed by clearing the
  /// injected style element.
  Future<void> _injectDarkModeCss() async {
    if (widget.isDarkMode) {
      // Inject the dark mode stylesheet.
      final css = DarkReaderCss.stylesheet;
      // Escape backticks and dollar signs for JavaScript string safety.
      final escapedCss = css
          .replaceAll('`', '\\`')
          .replaceAll(r'$', r'\$');
      final js = '''
(function() {
  var style = document.getElementById('old-reddit-dark-reader');
  if (!style) {
    style = document.createElement('style');
    style.id = 'old-reddit-dark-reader';
    style.textContent = `$escapedCss`;
    document.head.appendChild(style);
  }
})();
''';
      await _controller.runJavaScript(js);
      _darkModeInjected = true;
      debugPrint('[RedditWebView] Dark mode CSS injected');
    } else {
      // Remove the dark mode stylesheet if it exists.
      if (_darkModeInjected) {
        final js = '''
(function() {
  var style = document.getElementById('old-reddit-dark-reader');
  if (style) {
    style.remove();
  }
})();
''';
        await _controller.runJavaScript(js);
        _darkModeInjected = false;
        debugPrint('[RedditWebView] Dark mode CSS removed');
      }
    }
  }

  /// Injects phone-only layout fixes into the WebView.
  ///
  /// Tablets keep the existing desktop layout unchanged.
  Future<void> _injectMobileLayoutCss() async {
    if (!_pageLoaded) {
      return;
    }

    if (!_isPhoneLayout) {
      if (_mobileLayoutInjected) {
        final js = '''
(function() {
  var style = document.getElementById('old-reddit-mobile-layout');
  if (style) {
    style.remove();
  }
})();
''';
        await _controller.runJavaScript(js);
        _mobileLayoutInjected = false;
        debugPrint('[RedditWebView] Mobile layout CSS removed');
      }
      return;
    }

    final css = MobileLayoutCss.stylesheet;
    final escapedCss = css.replaceAll('`', '\\`').replaceAll(r'$', r'\$');
    final js = '''
(function() {
  var style = document.getElementById('old-reddit-mobile-layout');
  if (!style) {
    style = document.createElement('style');
    style.id = 'old-reddit-mobile-layout';
    style.textContent = `$escapedCss`;
    document.head.appendChild(style);
  }
})();
''';
    await _controller.runJavaScript(js);
    _mobileLayoutInjected = true;
    debugPrint('[RedditWebView] Mobile layout CSS injected');
  }

  /// Handles the Android system back button.
  ///
  /// If the WebView has navigation history, it goes back one page.
  /// Otherwise, it closes the app (default system behavior).
  Future<bool> onBackPressed() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false; // Do not close the app.
    }
    return true; // Allow the app to close.
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldClose = await onBackPressed();
        if (shouldClose && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          top: true,
          bottom: true,
          child: _buildBody(),
        ),
      ),
    );
  }

  /// Builds the main body of the WebView.
  ///
  /// Shows either:
  /// - The WebView with a loading progress indicator.
  /// - An error page with a retry button if loading failed.
  Widget _buildBody() {
    return Stack(
      children: [
        // The WebView fills the entire screen.
        WebViewWidget(controller: _controller),

        // Loading progress indicator at the top.
        if (_loadingProgress < 1.0 && !_hasError)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: _loadingProgress,
              minHeight: 3,
              backgroundColor: Colors.transparent,
            ),
          ),

        // Error overlay with retry button.
        if (_hasError)
          Positioned.fill(
            child: _buildErrorPage(),
          ),
      ],
    );
  }

  /// Builds a simple error page with a retry button.
  Widget _buildErrorPage() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load page',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _failedUrl ?? 'An error occurred while loading the page.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Retries loading the last failed URL, or reloads the current page.
  void _retry() {
    if (mounted) {
      setState(() {
        _hasError = false;
        _loadingProgress = 0.0;
      });
    }
    if (_failedUrl != null) {
      _controller.loadRequest(Uri.parse(_failedUrl!));
    } else {
      _controller.reload();
    }
  }

  @override
  void didUpdateWidget(RedditWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If dark mode changed while the WebView is already loaded, inject/remove CSS.
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      _injectDarkModeCss();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isPhoneLayout = MediaQuery.sizeOf(context).shortestSide < 600;
    if (_isPhoneLayout != isPhoneLayout) {
      _isPhoneLayout = isPhoneLayout;
      _injectMobileLayoutCss();
    }
  }
}
