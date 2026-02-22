import 'package:flutter/material.dart';
import '../../models/book_model.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorilerim", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: favoriteBooks.isEmpty
          ? const Center(child: Text("Henüz favori kitap eklemedin."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favoriteBooks.length,
              itemBuilder: (context, index) {
                final book = favoriteBooks[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(book.imageUrl, width: 50, height: 70, fit: BoxFit.cover),
                    ),
                    title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${book.author} - ${book.university}"),
                    trailing: Text("${book.price} TL", style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
    );
  }
}