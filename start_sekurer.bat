@echo off

echo Starting backend...
docker compose up -d

echo Waiting 10 seconds...
timeout /t 10 /nobreak > nul

echo Running migrations...
docker compose exec api alembic upgrade head

echo Building mobile APK...
docker run --rm -it ^
-v "%cd%:/work" ^
-v flutter_pub_cache:/root/.pub-cache ^
-w /work/mobile ^
instrumentisto/flutter:latest ^
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8000

echo.
echo APK READY:
echo mobile\build\app\outputs\flutter-apk\app-debug.apk

pause