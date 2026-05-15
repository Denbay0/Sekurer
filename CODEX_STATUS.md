# CODEX_STATUS

## Last update
2026-05-15 18:15

## Summary
Обновлён статус проекта для Mobile Milestone 1.3: добавлены честный отчёт о состоянии окружения/проверках, инструкция по безопасному bootstrap Flutter-проекта и скрипт автоматизации bootstrap. Проведена статическая проверка структуры `mobile/` без Flutter SDK.

## Environment
- Flutter SDK available: no
- Dart available: no
- Docker available: no
- Android SDK available: no
- OS/environment notes: Codex container (UTC), отсутствуют `flutter`, `dart` (как отдельная команда), `docker`; поэтому Flutter/Docker шаги не могут быть выполнены в этой среде.

## Commands attempted

| Command | Result | Notes |
|---|---|---|
| python -m compileall app | passed | Выполнено в `backend/`, компиляция модулей успешна. |
| docker compose config | not available | `docker: command not found`. |
| make smoke | failed | `scripts/smoke_test.sh` завершился ошибкой: API health-check не прошёл за 30 секунд (`http://localhost:8000/health`), backend не поднят в текущей среде. |
| flutter --version | not available | `flutter: command not found`. |
| flutter pub get | not available | Не запускалось: Flutter SDK отсутствует. |
| flutter analyze | not available | Не запускалось: Flutter SDK отсутствует. |
| flutter test | not available | Не запускалось: Flutter SDK отсутствует. |
| flutter build apk --debug | not available | Не запускалось: Flutter SDK отсутствует. |

## Current project state

### Backend
- status: исходники присутствуют; базовая статическая python-проверка (`compileall`) проходит.
- known issues: docker/compose недоступен в этой среде, поэтому локально внутри Codex нельзя поднять стек и пройти smoke end-to-end.

### Mobile
- status: присутствует Dart/Flutter код приложения (экраны, сервисы, core, тест), но папки `android/` и `ios/` полноценного Flutter-шаблона ещё не сгенерированы.
- android folder exists: yes (только `android/key.properties.example`)
- ios folder exists: no
- is full Flutter project: no
- known issues:
  - Flutter SDK отсутствует в среде, невозможно выполнить `flutter create`, `flutter analyze`, `flutter test`, `flutter build`.
  - Проверка release signing на Gradle-уровне заблокирована до генерации Android проекта.

Статическая проверка mobile-кода (без Flutter SDK):
- структура `mobile/` валидна для pre-bootstrap состояния (есть `lib/`, `test/`, `pubspec.yaml`, `analysis_options.yaml`);
- в `mobile/lib/screens/` нет импортов `main.dart`;
- `AppState` вынесен в `mobile/lib/core/app_state.dart` и используется в `main.dart`;
- `pubspec.yaml` содержит зависимости: `dio`, `file_picker`, `flutter_secure_storage`, `intl`, `provider`.

Android release signing status:
- release signing instructions are documented;
- actual Gradle signing config cannot be applied until `flutter create` generates `android/app/build.gradle` or `android/app/build.gradle.kts`.
- после генерации проекта нужно: добавить `signingConfig` в Gradle-конфиг, добавить `key.properties` в `.gitignore`, оставить `key.properties.example`.

## What is ready
- Добавлен централизованный статус-отчёт `CODEX_STATUS.md`.
- Добавлена инструкция `mobile/FLUTTER_SETUP.md` для безопасного bootstrap на машине с Flutter SDK.
- Добавлен автоматизированный fail-fast скрипт `scripts/bootstrap_flutter_mobile.sh`.
- README дополнен секцией про Codex status report и локальный bootstrap при отсутствии Flutter SDK.

## What is blocked
- Невозможность выполнить Flutter-команды из-за отсутствия Flutter SDK.
- Невозможность применить/проверить Gradle signing config до генерации Android проекта.
- Невозможность поднять backend stack через docker в текущем окружении.

## Next recommended steps
1. На локальной машине с Flutter SDK запустить `bash scripts/bootstrap_flutter_mobile.sh`.
2. Проверить, что после `flutter create` сохранены/не перезаписаны ключевые файлы: `lib/`, `pubspec.yaml`, `analysis_options.yaml`.
3. После генерации Android проекта добавить release signing в `android/app/build.gradle` или `build.gradle.kts`.
4. Добавить `mobile/android/key.properties` в `.gitignore`, оставить `mobile/android/key.properties.example` в репозитории.
5. Выполнить локально: `flutter analyze`, `flutter test`, `flutter build apk --debug ...` и зафиксировать результаты в следующем обновлении `CODEX_STATUS.md`.
