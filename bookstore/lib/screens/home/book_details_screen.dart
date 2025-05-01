import 'package:bookstore/screens/home/read_switch.dart';
import 'package:bookstore/screens/home/tag_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BookDetailsScreen extends StatefulWidget {
  final String bookId;

  const BookDetailsScreen({super.key, required this.bookId});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  late DocumentReference<Map<String, dynamic>> _bookRef;
  late TextEditingController _tagController;

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser!.uid;
    _bookRef = FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("books")
        .doc(widget.bookId);
    _tagController = TextEditingController();
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Book Details")),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _bookRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data();
          if (data == null) {
            return const Center(child: Text("Book not found"));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data["cover"] != null)
                  Center(child: Image.network(data["cover"], height: 200)),
                const SizedBox(height: 16),
                Text(
                  data["title"] ?? "Unknown Title",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text("Author: ${data["authors"]?.join(', ') ?? "Unknown"}"),
                const SizedBox(height: 16),
                ReadSwitch(bookRef: _bookRef),
                const SizedBox(height: 16),
                TagManager(bookRef: _bookRef),
              ],
            ),
          );
        },
      ),
    );
  }
}
