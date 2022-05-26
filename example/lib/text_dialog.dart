import 'package:flutter/material.dart';

class TextDialog extends StatelessWidget {
  final String text;

  static Future<void> showTextDialog(BuildContext context, String text) async {
    return await showDialog(
        context: context, builder: (context) => TextDialog(text: text));
  }

  const TextDialog({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text),
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
