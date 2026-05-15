import 'package:flutter_test/flutter_test.dart';
import 'package:sekurer_mobile/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('login screen renders', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Вход'), findsOneWidget);
    expect(find.text('Войти'), findsOneWidget);
    expect(find.text('Создать аккаунт'), findsOneWidget);
  });
}
