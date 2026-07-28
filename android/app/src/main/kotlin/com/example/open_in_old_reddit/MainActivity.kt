package com.example.open_in_old_reddit

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Main entry point for the Old Reddit Viewer Android activity.
///
/// This activity handles deep link intents from Reddit URLs.
/// When a Reddit link is opened from another app (including Google Search),
/// Android delivers the URL via an intent. This activity uses two mechanisms
/// to capture the URL:
///
/// 1. The `app_links` plugin (which registers a NewIntentListener automatically)
/// 2. A direct [MethodChannel] fallback that queries the intent data
///
/// The [launchMode] is set to "singleTask" in AndroidManifest.xml so that
/// when a new deep link arrives while the app is already running, Android
/// calls [onNewIntent] instead of creating a new activity instance.
class MainActivity : FlutterActivity() {
    /// Method channel for direct intent communication with Dart.
    private val CHANNEL = "com.example.open_in_old_reddit/intent"

    /// The most recent intent URL received (used for both initial and ongoing links).
    private var latestIntentUrl: String? = null
    private var intentChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Set up a method channel so Dart can query the intent URL directly.
        // This serves as a fallback alongside the app_links plugin to ensure
        // deep links are always captured, including from ACTION_SEND intents
        // that app_links might ignore.
        intentChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )
        intentChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialIntentUrl" -> {
                    result.success(latestIntentUrl ?: extractUrlFromIntent(intent))
                }
                "getLatestIntentUrl" -> {
                    result.success(latestIntentUrl)
                }
                else -> result.notImplemented()
            }
        }
    }

    /// Processes the activity's intent to extract a Reddit URL.
    ///
    /// This is called both from [onCreate] (via the intent parameter) and
    /// from [onNewIntent] (when a new link arrives while the app is running).
    /// The extracted URL is stored in [latestIntentUrl] for the Dart layer
    /// to retrieve via the method channel.
    private fun processIntent(intent: Intent?) {
        val url = extractUrlFromIntent(intent)
        if (url != null) {
            latestIntentUrl = url
            android.util.Log.d(
                "MainActivity",
                "Intent processed: $url"
            )
            // app_links does not deliver ACTION_SEND intents. Forward shares
            // received while Flutter is already running through our channel.
            intentChannel?.invokeMethod("onIntentUrl", url)
        }
    }

    /// Called when the activity is first created.
    /// Extracts the initial deep link URL from the launching intent.
    override fun onStart() {
        super.onStart()
        // Process the intent that launched the activity.
        // Using onStart ensures the Flutter engine is ready.
        processIntent(intent)

        // Also check getIntent() as a fallback (defensive).
        if (latestIntentUrl == null) {
            processIntent(getIntent())
        }
    }

    /// Called when a new intent arrives while the activity is already running.
    ///
    /// This happens when the user opens another Reddit link while the app
    /// is already open. The [launchMode] = "singleTask" ensures this method
    /// is called instead of creating a new activity.
    ///
    /// Both the app_links plugin (via NewIntentListener) and our method channel
    /// intercept this intent. We call [setIntent] so that getIntent() always
    /// returns the latest intent data.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        processIntent(intent)
        setIntent(intent)
    }

    companion object {
        /// Extracts a Reddit URL from the given [Intent], if present.
        ///
        /// Checks multiple sources in priority order:
        /// 1. Intent data URI (standard deep link / ACTION_VIEW)
        /// 2. Intent's EXTRA_TEXT (used by ACTION_SEND / share intents)
        ///
        /// This covers the three main ways Reddit links reach our app:
        /// - Standard deep links (ACTION_VIEW with a Reddit URL)
        /// - Shared URLs from other apps (ACTION_SEND with EXTRA_TEXT)
        /// - App links via Android's verified links system
        fun extractUrlFromIntent(intent: Intent?): String? {
            if (intent == null) return null

            // Strategy 1: Check the intent data URI directly.
            // This is the standard approach for ACTION_VIEW intents.
            extractRedditUrl(intent.dataString)?.let { return it }

            // Shared text can include a title, description, or a search-engine
            // redirect URL in addition to the Reddit URL itself.
            extractRedditUrl(intent.getStringExtra(Intent.EXTRA_TEXT))?.let { return it }
            extractRedditUrl(intent.getStringExtra(Intent.EXTRA_HTML_TEXT))?.let { return it }

            // Some share sheets place the URL only in ClipData.
            intent.clipData?.let { clipData ->
                for (index in 0 until clipData.itemCount) {
                    val item = clipData.getItemAt(index)
                    extractRedditUrl(item.text?.toString())?.let { return it }
                    extractRedditUrl(item.uri?.toString())?.let { return it }
                }
            }

            return null
        }

        /// Extracts the first direct Reddit URL from a shared value.
        ///
        /// Share targets are free-form text, so this accepts a bare URL, a
        /// Google/Bing redirect wrapper, or prose containing one of those URLs.
        private fun extractRedditUrl(value: String?): String? {
            if (value.isNullOrBlank()) return null

            val candidates = buildList {
                add(value.trim())
                URL_PATTERN.findAll(value).forEach { add(it.value) }
            }

            for (candidate in candidates) {
                val cleaned = candidate.trim().trimEnd('.', ',', ';', ':', ')', ']', '}')
                val uri = runCatching { Uri.parse(cleaned) }.getOrNull() ?: continue
                val unwrapped = unwrapRedirectUrl(uri)
                if (unwrapped != null) return unwrapped
                if (isPossibleRedditUrl(cleaned)) return cleaned
            }

            return null
        }

        /// Checks whether [url] is a direct URL for a supported Reddit host.
        private fun isPossibleRedditUrl(url: String): Boolean {
            val uri = runCatching { Uri.parse(url.trim()) }.getOrNull() ?: return false
            return (uri.scheme == "http" || uri.scheme == "https") &&
                uri.host.lowercase() in REDDIT_HOSTS
        }

        /// Attempts to extract a Reddit URL from common search-engine redirect wrappers.
        ///
        /// Google and Bing often wrap outbound links in their own URLs. This method
        /// checks the most common query parameters and returns the first Reddit URL it
        /// can find, if any.
        private fun unwrapRedirectUrl(uri: Uri): String? {
            val candidates = listOf(
                uri.getQueryParameter("q"),
                uri.getQueryParameter("url"),
                uri.getQueryParameter("u"),
                uri.getQueryParameter("target"),
                uri.getQueryParameter("dest"),
                uri.getQueryParameter("r"),
                uri.fragment?.takeIf { it.contains("reddit.com", ignoreCase = true) || it.contains("redd.it", ignoreCase = true) }
            )

            for (candidate in candidates) {
                val cleaned = candidate
                    ?.trim()
                    ?.replace("\"", "")
                    ?.replace("'", "")
                extractRedditUrl(cleaned)?.let { return it }
            }

            return null
        }

        private val REDDIT_HOSTS = setOf(
            "reddit.com",
            "www.reddit.com",
            "old.reddit.com",
            "m.reddit.com",
            "redd.it",
        )

        private val URL_PATTERN = Regex("https?://[^\\s<>\\\"']+")
    }
}
