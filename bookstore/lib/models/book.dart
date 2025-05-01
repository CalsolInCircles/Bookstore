class Book {
  final String title;
  final String author;

  Book({required this.title, required this.author});

  factory Book.fromFirestore(Map<String, dynamic> data) {
    return Book(
      title: data['title'] ?? 'No Title',
      author: data['author'] ?? 'No Author',
    );
  }
}
