// services/book_service.dart
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<QueryDocumentSnapshot<Object?>?> pickNextBook(
    Map<String, dynamic> filters,
  ) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    Query query = FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("books")
        .where('read', isEqualTo: filters['isRead']);

    if (filters['tags'] != null && (filters['tags'] as List).isNotEmpty) {
      query = query.where('tags', arrayContainsAny: filters['tags']);
    }

    if (filters['genre'] != null) {
      query = query.where('genre', isEqualTo: filters['genre']);
    }

    final snapshot = await query.get();
    final books = snapshot.docs;

    if (books.isEmpty) return null;

    final randomIndex = Random().nextInt(books.length);
    return books[randomIndex];
  }

  Future<Map<String, List<String>>> getUserTagsAndGenres(String userId) async {
    final snapshot =
        await _firestore
            .collection("users")
            .doc(userId)
            .collection("books")
            .get();

    Set<String> tags = {};
    Set<String> genres = {};

    for (var doc in snapshot.docs) {
      final book = doc.data();
      // Extract tags if they exist
      if (book['tags'] != null) {
        tags.addAll(List<String>.from(book['tags']));
      }
      // Extract genre if it exists
      if (book['genres'] != null) {
        genres.addAll(List<String>.from(book['genres']));
      }
    }
    print({'tags': tags.toList(), 'genres': genres.toList()});
    return {'tags': tags.toList(), 'genres': genres.toList()};
  }
}
