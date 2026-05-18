# iOS Build Instructions

Run these commands on macOS with Xcode, CocoaPods, and Flutter installed:

```bash
cd mobile
flutter clean
flutter pub get
flutter build ios --release --dart-define=API_BASE_URL=http://<SERVER_LAN_IP>:8000
```

For a local iOS simulator against a backend on the same Mac:

```bash
flutter run -d ios --dart-define=API_BASE_URL=http://localhost:8000
```

For a physical iPhone:

```bash
flutter run -d <DEVICE_ID> --dart-define=API_BASE_URL=http://<LAN_IP>:8000
```

Before App Store/TestFlight distribution, configure:
- Bundle identifier in `ios/Runner.xcodeproj`
- Apple Team signing in Xcode
- Production backend URL
- Release version/build number in `mobile/pubspec.yaml`
