import 'package:bookstore/screens/home/book_details_screen.dart';
import 'package:bookstore/services/book_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RandomBookFilterScreen extends StatefulWidget {
  const RandomBookFilterScreen({super.key});

  @override
  State<RandomBookFilterScreen> createState() => _RandomBookFilterScreenState();
}

class _RandomBookFilterScreenState extends State<RandomBookFilterScreen> {
  final BookService _bookService = BookService();
  bool? _isRead;
  List<String> _selectedTags = [];
  String? _selectedGenre;

  List<String> tags = [];
  List<String> genres = [];

  // Load tags and genres
  Future<void> _loadFilters() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final filters = await _bookService.getUserTagsAndGenres(userId);

    setState(() {
      tags = filters['tags']!;
      genres = filters['genres']!;
    });
  }

  // Handle book selection
  void _handleBookSelection() async {
    final isRead = _isRead ?? false;
    final selectedBook = await _bookService.pickNextBook({
      'isRead': isRead,
      'tags': _selectedTags,
      'genre': _selectedGenre,
    });

    if (!mounted) return;

    if (selectedBook == null) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: Text("No Matches"),
              content: Text("No books found matching your filters."),
            ),
      );
      Future.delayed(Duration(seconds: 3), () {
        Navigator.of(context, rootNavigator: true).pop();
      });
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailsScreen(bookId: selectedBook.id),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadFilters(); // Load filters once when the widget is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Set Filters")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Read Status
              Text(
                "Read Status",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Text("Read"),
                  Switch(
                    value: _isRead ?? false,
                    onChanged: (bool value) {
                      setState(() {
                        _isRead = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tags
              const Text(
                "Tags",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              tags
                      .isEmpty // Use tags loaded in initState
                  ? Center(child: CircularProgressIndicator())
                  : Wrap(
                    spacing: 8,
                    children:
                        tags.map((tag) {
                          return FilterChip(
                            label: Text(tag),
                            selected: _selectedTags.contains(tag),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  _selectedTags.add(tag);
                                } else {
                                  _selectedTags.remove(tag);
                                }
                              });
                            },
                          );
                        }).toList(),
                  ),
              const SizedBox(height: 16),

              // Genre
              const Text(
                "Genre",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              genres
                      .isEmpty // Use genres loaded in initState
                  ? Center(child: CircularProgressIndicator())
                  : DropdownButton<String>(
                    value: _selectedGenre,
                    hint: const Text("Select Genre"),
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedGenre = newValue;
                      });
                    },
                    items:
                        genres.map((String genre) {
                          return DropdownMenuItem<String>(
                            value: genre,
                            child: Text(genre),
                          );
                        }).toList(),
                  ),
              const SizedBox(height: 16),

              // Apply
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    _handleBookSelection();
                  },
                  child: const Text("Apply Filters"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
