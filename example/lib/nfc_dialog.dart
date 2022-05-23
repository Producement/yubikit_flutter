import 'package:flutter/material.dart';

class NFCDialog extends StatelessWidget {
  static Future<void> showNfcDialog(BuildContext context) async {
    return await showDialog(
        context: context, builder: (context) => const NFCDialog());
  }

  const NFCDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text("Remove NFC key"),
        ],
      ),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Ok"),
        ),
      ],
    );
  }
}
