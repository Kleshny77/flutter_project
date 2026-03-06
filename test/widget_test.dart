import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_project/app_theme.dart';

void main() {
  testWidgets('App theme has primary blue color', (WidgetTester tester) async {
    expect(AppTheme.primaryBlue, isNotNull);
    expect(AppTheme.primaryBlue, const Color(0xFF2563EB));
  });
}
