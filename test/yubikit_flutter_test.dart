import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yubikit_flutter/piv/piv_session.dart';
import 'package:yubikit_flutter/yubikit_flutter.dart';

void main() {
  const MethodChannel channel = MethodChannel('yubikit_flutter');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      if(methodCall.method == "pivReset"){
        return null;
      }
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('reset', () async {
    YubikitFlutterPivSession pivSession = YubikitFlutter.pivSession();
    await pivSession.reset();
  });
}
