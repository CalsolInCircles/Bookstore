import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReadSwitch extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> bookRef;
  const ReadSwitch({super.key, required this.bookRef});

  @override
  State<ReadSwitch> createState() => _ReadSwitchState();
}

class _ReadSwitchState extends State<ReadSwitch> {
  bool? isRead;

  @override
  void initState() {
    super.initState();
    widget.bookRef.get().then((snapshot) {
      if (snapshot.exists) {
        setState(() {
          isRead = snapshot.data()?["read"] ?? false;
        });
      }
    });
  }

  void _updateRead(bool newValue) async {
    setState(() => isRead = newValue);
    await widget.bookRef.update({"read": newValue});
  }

  @override
  Widget build(BuildContext context) {
    if (isRead == null) return const CircularProgressIndicator();
    return Row(
      children: [
        const Text("Read:"),
        Switch(value: isRead!, onChanged: _updateRead),
      ],
    );
  }
}
