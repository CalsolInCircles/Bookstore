import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class TagManager extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> bookRef;
  const TagManager({super.key, required this.bookRef});

  @override
  State<TagManager> createState() => _TagManagerState();
}

class _TagManagerState extends State<TagManager> {
  List<String> tags = [];
  final TextEditingController _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  void _loadTags() async {
    final doc = await widget.bookRef.get();
    final data = doc.data();
    if (data != null && data["tags"] != null) {
      setState(() {
        tags = List<String>.from(data["tags"]);
      });
    }
  }

  Future<void> _addTag(String tag) async {
    tag = tag.trim();
    if (tag.isEmpty || tags.contains(tag)) return;

    await widget.bookRef.update({
      "tags": FieldValue.arrayUnion([tag]),
    });

    setState(() {
      tags.add(tag);
      _tagController.clear();
    });
  }

  Future<void> _removeTag(String tag) async {
    await widget.bookRef.update({
      "tags": FieldValue.arrayRemove([tag]),
    });

    setState(() {
      tags.remove(tag);
    });
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tags:",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children:
              tags
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                      onDeleted: () => _removeTag(tag),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _tagController,
          decoration: InputDecoration(
            labelText: "Add a tag",
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addTag(_tagController.text),
            ),
          ),
        ),
      ],
    );
  }
}
