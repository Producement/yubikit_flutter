import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yubikit_flutter/yubikit_flutter.dart';

void main() {
  const MethodChannel channel = MethodChannel('yubikit_flutter_piv');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'pivReset') {
        return null;
      }
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('reset', () async {
    var pivSession = YubikitFlutter.piv();
    await pivSession.reset();
  });
}
