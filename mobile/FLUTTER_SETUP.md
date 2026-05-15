# Flutter setup for `mobile/`

Этот документ предназначен для разработчика с установленным Flutter SDK.

## 1) Проверка окружения Flutter

```bash
flutter doctor
```

Убедитесь, что Flutter, Dart, Android toolchain (и при необходимости Xcode для iOS) настроены корректно.

## 2) Безопасный bootstrap текущей папки `mobile/`

```bash
cd mobile
flutter create --platforms=android,ios .
```

Команда сгенерирует недостающие платформенные файлы (`android/`, `ios/`) в текущей папке.

## 3) После `flutter create` проверить, что не потерялись проектные файлы

Проверьте наличие и корректность:
- `lib/`
- `pubspec.yaml`
- `analysis_options.yaml`

Если `flutter create` что-то перезаписал нежелательно — восстановите изменения из git и повторите bootstrap аккуратно.

## 4) Установка зависимостей

```bash
flutter pub get
```

## 5) Форматирование

```bash
dart format lib test
```

## 6) Проверки качества

```bash
flutter analyze
flutter test
```

## 7) Сборка debug APK

```bash
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

## 8) Сборка release APK (после настройки подписи)

```bash
flutter build apk --release --dart-define=API_BASE_URL=http://<SERVER_LAN_IP>:8000
```

Перед release-сборкой обязательно настройте signing в `android/app/build.gradle` или `android/app/build.gradle.kts` и используйте локальный `android/key.properties` (не коммитить в git).
