import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class EditBookScreen extends StatefulWidget {
  final dynamic book;

  const EditBookScreen({super.key, required this.book});

  @override
  State<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  late TextEditingController titleController;
  late TextEditingController priceController;
  late TextEditingController descController;

  final api = ApiService();

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.book.title);
    priceController = TextEditingController(text: widget.book.price.toString());
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

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("İlan Düzenle")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: titleController, decoration: InputDecoration(labelText: "Başlık")),
            TextField(controller: priceController, decoration: InputDecoration(labelText: "Fiyat")),
            TextField(controller: descController, decoration: InputDecoration(labelText: "Açıklama")),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateBook,
              child: Text("Güncelle"),
            )
          ],
        ),
      ),
    );
  }
}