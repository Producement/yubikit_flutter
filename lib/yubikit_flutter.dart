import 'package:yubikit_openpgp/yubikit_openpgp.dart';

import 'piv/piv.dart';
import 'smartcard/smartcard.dart';

export 'package:yubikit_openpgp/yubikit_openpgp.dart';

export 'piv/key_algorithm.dart';
export 'piv/key_type.dart';
export 'piv/management_key_type.dart';
export 'piv/pin_policy.dart';
export 'piv/piv.dart';
export 'piv/slot.dart';
export 'piv/touch_policy.dart';
export 'smartcard/smartcard.dart';

class YubikitFlutter {
  const YubikitFlutter._internal();

  static YubikitFlutterPiv piv() {
    return const YubikitFlutterPiv();
  }

  static YubikitFlutterSmartCard smartCard() {
    return const YubikitFlutterSmartCard();
  }

  static YubikitOpenPGP openPGP({PinProvider? pinProvider}) {
    return YubikitOpenPGP(
        const YubikitFlutterSmartCard(), pinProvider ?? PinProvider());
  }
}
