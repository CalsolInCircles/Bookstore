import 'package:flutter/material.dart';
import 'isbn_scanner_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookstore/helpers/show_book_options.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: Text('Home Library')),

      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                height: 100,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.blue),
                alignment: Alignment.centerLeft,
                child: Text(
                  "📚 My Library",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Main navigation items
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.blue),
                title: Text("Scan Book"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BarcodeScannerPage()),
                  );
                },
              ),

              Spacer(),

              // Log out item at bottom
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text("Log Out", style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await FirebaseAuth.instance.signOut();
                },
              ),
            ],
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection("users")
                .doc(userId)
                .collection("books")
                .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No books found."));
          }

          final books = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index].data() as Map<String, dynamic>;
              final docId = books[index].id;
              print("Book: ${book}");
              return GestureDetector(
                onTap: () => showBookOptions(context, book, docId),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image:
                        book["cover"] != null
                            ? DecorationImage(
                              image: NetworkImage(book["cover"]),
                              fit: BoxFit.cover,
                            )
                            : null,
                    color: Colors.grey.shade300,
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.grey.shade700, Colors.transparent],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Text(
                          book["title"] ?? "Unknown Title",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            shadows: [
                              Shadow(blurRadius: 4, color: Colors.black),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
