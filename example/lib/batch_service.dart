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
    final result =
        (await results.toList()).whereType<SuccessfulResponse>().toList();
    return OpenPGPInfo(
        OpenPGPVersion.fromBytes(result[0].response),
        PinRetries.fromBytes(result[1].response),
        TouchModeValues.parse(result[2].response),
        TouchModeValues.parse(result[3].response),
        TouchModeValues.parse(result[4].response));
  }

  Future<Map<KeySlot, KeyData?>> getAllKeys() async {
    final commands = [
      _commands.getAsymmetricPublicKey(KeySlot.signature),
      _commands.getAsymmetricPublicKey(KeySlot.encryption),
      _commands.getAsymmetricPublicKey(KeySlot.authentication),
    ];
    final results =
        await _smartCardInterface.sendCommands(Application.openpgp, commands);
    final result = await results.toList();
    final entries = <MapEntry<KeySlot, KeyData?>>[];
    entries.add(getEntry(KeySlot.signature, result[0]));
    entries.add(getEntry(KeySlot.encryption, result[1]));
    entries.add(getEntry(KeySlot.authentication, result[2]));
    return Map.fromEntries(entries);
  }

  MapEntry<KeySlot, KeyData?> getEntry(
      KeySlot keySlot, SmartCardResponse response) {
    if (response is SuccessfulResponse) {
      return MapEntry(keySlot, KeyData.fromBytes(response.response, keySlot));
    }
    return MapEntry(keySlot, null);
  }
}

class OpenPGPInfo {
  final OpenPGPVersion openPGPVersion;
  final PinRetries retries;
  final TouchMode signatureTouch;
  final TouchMode encryptionTouch;
  final TouchMode authenticationTouch;

  const OpenPGPInfo(this.openPGPVersion, this.retries, this.signatureTouch,
      this.encryptionTouch, this.authenticationTouch);
}
