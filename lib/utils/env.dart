import 'package:flutter/widgets.dart';

/// Returns true when running under flutter_test (TestWidgetsFlutterBinding).
bool isInFlutterTest() {
  final binding = WidgetsBinding.instance;
  if (binding == null) return false;
  final type = binding.runtimeType.toString();
  return type.contains('TestWidgetsFlutterBinding');
}

