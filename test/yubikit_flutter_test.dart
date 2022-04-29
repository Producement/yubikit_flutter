import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yubikit_flutter/yubikit_flutter.dart';

void main() {
  const MethodChannel channel = MethodChannel('yubikit_flutter');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('connect', () async {
    //expect(await YubikitFlutter.connect(), '42');
  });
}
