import 'package:bookstore/screens/home/random_book_filter_screen.dart';
import 'package:flutter/material.dart';
import 'isbn_scanner_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookstore/helpers/show_book_options.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  String _searchQuery = '';
  String _sortBy = 'title';

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Home Library'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search books...',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value.toLowerCase());
                    },
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _sortBy,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _sortBy = value);
                    }
                  },
                  items:
                      ['title', 'scannedAt'].map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(
                            option == 'scannedAt' ? 'Recently Added' : 'Title',
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),

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
              ListTile(
                leading: Icon(Icons.shuffle, color: Colors.blue),
                title: Text("Random Book"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RandomBookFilterScreen()),
                  );
                },
              ),
              Spacer(),
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

          List<QueryDocumentSnapshot> books = snapshot.data!.docs;
          List<Map<String, dynamic>> filteredBooks =
              books
                  .map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    data['docId'] = doc.id;
                    return data;
                  })
                  .where((book) {
                    final title =
                        (book['title'] ?? '').toString().toLowerCase();
                    return title.contains(_searchQuery);
                  })
                  .toList();

          if (_sortBy == 'title') {
            filteredBooks.sort(
              (a, b) => (a['title'] ?? '').compareTo(b['title'] ?? ''),
            );
          } else if (_sortBy == 'scannedAt') {
            filteredBooks.sort(
              (a, b) => (b['scannedAt'] as Timestamp).compareTo(
                a['scannedAt'] as Timestamp,
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemCount: filteredBooks.length,
            itemBuilder: (context, index) {
              final book = filteredBooks[index];
              final docId = book['docId'];

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
