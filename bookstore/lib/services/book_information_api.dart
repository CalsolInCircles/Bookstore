import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>?> fetchBookByIsbn(String isbn) async {
  final response = await http.get(
    Uri.parse('https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn'),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data["totalItems"] > 0) {
      return data["items"][0]["volumeInfo"];
    }
  }
  return null;
}
