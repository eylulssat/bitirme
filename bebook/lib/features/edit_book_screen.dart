import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/book_card.dart';

class EditBookScreen extends StatefulWidget {
  final Book book;

  const EditBookScreen({super.key, required this.book});

  @override
  State<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  late TextEditingController titleController;
  late TextEditingController priceController;
  late TextEditingController descController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.book.title);
    priceController = TextEditingController(text: widget.book.price);
    descController = TextEditingController(text: widget.book.description);
  }

  void updateBook() async {
    final res = await ApiService.updateBook(
      widget.book.bookId,
      widget.book.userId,
      titleController.text,
      double.parse(priceController.text),
      descController.text,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res['message'])),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("İlan Düzenle")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Başlık"),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: "Fiyat"),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Açıklama"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateBook,
              child: const Text("Güncelle"),
            )
          ],
        ),
      ),
    );
  }
}