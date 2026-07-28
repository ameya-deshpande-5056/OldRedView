# Old Reddit Viewer

An Android Flutter app that opens Reddit links in `old.reddit.com` inside an in-app WebView.

## GitHub releases

Pushing a version tag such as `v0.0.1` runs the Android release workflow and attaches a signed APK to the matching GitHub Release. The tag controls the APK version: `vMAJOR.MINOR.PATCH` becomes Android version name `MAJOR.MINOR.PATCH` and version code `MAJOR * 1,000,000 + MINOR * 1,000 + PATCH`. For example, `v0.0.1` builds version name `0.0.1` and version code `1`.

Before the first release, add these repository Action secrets:

- `ANDROID_KEYSTORE_BASE64`: Base64-encoded release keystore file.
- `ANDROID_KEYSTORE_PASSWORD`: Password for that keystore.
- `ANDROID_KEY_ALIAS`: Alias of the release key.
- `ANDROID_KEY_PASSWORD`: Password for the release key.

The private keystore and `android/key.properties` are ignored by Git. A manually dispatched workflow still builds an APK as a downloadable workflow artifact, but only tag builds publish under GitHub Releases.
