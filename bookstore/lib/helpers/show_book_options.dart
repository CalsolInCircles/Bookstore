import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

void showBookOptions(
  BuildContext context,
  Map<String, dynamic> book,
  String docId,
) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder:
        (context) => Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text("View Details"),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text("Delete"),
                onTap: () async {
                  Navigator.pop(context);
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('books')
                        .doc(docId)
                        .delete();
                  }
                },
              ),
            ],
          ),
        ),
  );
}
