# API keys setup (Busify Flutter app)

## Backend URL

Configured in `lib/utils/api_config.dart`:

`https://busify-eb94148f435f.herokuapp.com`

## Google Maps

Enable these APIs in [Google Cloud Console](https://console.cloud.google.com/):

1. **Maps SDK for Android**
2. **Maps SDK for iOS**
3. **Geocoding API** (parent address from GPS)

Optional (if you later switch routing from OSRM to Google):

4. **Directions API**

### Where to put the key

| Platform | File |
|----------|------|
| Android | `android/app/src/main/res/values/strings.xml` → `google_maps_key` |
| iOS | `ios/Runner/Info.plist` → `GMSApiKey` |
| Flutter run/build (geocoding) | `--dart-define=GOOGLE_MAPS_API_KEY=your_key` |

Example:

```bash
flutter run --dart-define=GOOGLE_MAPS_API_KEY=AIza...
```

Replace `YOUR_GOOGLE_MAPS_API_KEY` placeholders in the Android/iOS files above with the same key.
