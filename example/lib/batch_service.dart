import 'package:tuple/tuple.dart';
import 'package:yubikit_flutter/yubikit_flutter.dart';

class BatchOpenPGPService {
  final YubikitOpenPGPCommands _commands;
  final SmartCardInterface _smartCardInterface;

  const BatchOpenPGPService(this._smartCardInterface, this._commands);

  Future<OpenPGPInfo> getInfo() async {
    final commands = [
      _commands.getOpenPGPVersion(),
      _commands.getRemainingPinTries(),
      _commands.getTouch(KeySlot.signature),
      _commands.getTouch(KeySlot.encryption),
      _commands.getTouch(KeySlot.authentication)
    ];
    final results =
        await _smartCardInterface.sendCommands(Application.openpgp, commands);
    final result = await results.toList();
    return OpenPGPInfo(
        Tuple2(result[0][6], result[0][7]),
        PinRetries(result[1][4], result[1][5], result[1][6]),
        TouchModeValues.parse(result[2]),
        TouchModeValues.parse(result[3]),
        TouchModeValues.parse(result[4]));
  }
}

class OpenPGPInfo {
  final Tuple2 openPGPVersion;
  final PinRetries retries;
  final TouchMode signatureTouch;
  final TouchMode encryptionTouch;
  final TouchMode authenticationTouch;

  const OpenPGPInfo(this.openPGPVersion, this.retries, this.signatureTouch,
      this.encryptionTouch, this.authenticationTouch);
}