import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  final int myId;
  const ChatListScreen({super.key, required this.myId});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<dynamic> chatList = [];
  bool isLoading = true;
  int? myId;
  String? myName;

  @override
  void initState() {
    super.initState();
    _fetchChatList();
  }

  // 1. LİSTEYİ ÇEKEN FONKSİYON
  Future<void> _fetchChatList() async {
    try {
      final response = await http
          .get(Uri.parse("http://192.168.67.130:8000/chats/${widget.myId}"))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            chatList = jsonDecode(response.body);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Liste çekme hatası: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // 2. SİLME YAPAN FONKSİYON
  Future<void> deleteChat(int otherId, int bookId) async {
    try {
      final response = await http.delete(
        Uri.parse(
            "http://192.168.67.130:8000/chats/delete?my_id=${widget.myId}&other_id=$otherId&book_id=$bookId"),
      );

      if (response.statusCode == 200) {
        _fetchChatList();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Sohbet silindi"),
                backgroundColor: Colors.purple),
          );
        }
      }
    } catch (e) {
      print("Silme hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6C63FF);

    // --- BURASI YENİ: GİRİŞ KONTROLÜ KİLİDİ ---
    if (widget.myId == 0) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_outline,
                      size: 80, color: primaryColor),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Giriş Yapmalısınız",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Mesajlarınızı görmek için lütfen önce hesabınıza giriş yapın.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    // BURASI ÖNEMLİ: Kendi giriş sayfanın ismini buraya yazmalısın
                    // Eğer route kullanmıyorsan Navigator.push kullanabilirsin
                    Navigator.pushNamed(context, '/login');
                  },
                  child: const Text("Giriş Yap",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }
    // --- KİLİT KISMI BURADA BİTİYOR ---

    // SENİN MEVCUT KODUN (HİÇ DOKUNULMADI):
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("Mesajlarım",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : chatList.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  itemCount: chatList.length,
                  itemBuilder: (context, index) {
                    final chat = chatList[index];
                    return _buildChatCard(chat, primaryColor, context);
                  },
                ),
    );
  }

  // MESAJ KARTINI AYRI BİR WIDGET OLARAK SINIF İÇİNDE TANIMLADIK
  Widget _buildChatCard(
      dynamic chat, Color primaryColor, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: primaryColor.withOpacity(0.1),
            backgroundImage: chat['profile_image'] != null &&
                    chat['profile_image'].toString().isNotEmpty
                ? NetworkImage(
                    "http://192.168.67.130:8000/${chat['profile_image'].toString().replaceAll('\\', '/')}")
                : null,
            child: (chat['profile_image'] == null ||
                    chat['profile_image'].toString().isEmpty)
                ? Text(
                    chat['receiver_name'][0].toUpperCase(),
                    style: TextStyle(
                        color: primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  )
                : null,
          ),
          title: Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              chat['receiver_name'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "📚 ${chat['book_title']}",
                  style: TextStyle(
                      color: primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                chat['last_message'] ?? "Henüz mesaj yok...",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min, // Sadece ikonlar kadar yer kaplar
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.redAccent, size: 20),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Sohbeti Sil"),
                      content: const Text(
                          "Bu sohbeti silmek istediğinize emin misiniz?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("İptal"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            deleteChat(chat['receiver_id'], chat['book_id']);
                          },
                          child: const Text("Sil",
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
          onTap: () {
            print("Backend'den gelen chat verisi: $chat");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(
                  receiverId: chat['receiver_id'],
                  receiverName: chat['receiver_name'],
                  receiverImage: chat['profile_image'],
                  bookTitle: chat['book_title'],
                  bookId: chat['book_id'],
                  // BURAYA DİKKAT:
                  myId: myId ?? 0, // Eğer myId boşsa 0 gönder
                  myName: myName ??
                      "Kullanıcı", // Eğer myName boşsa "Kullanıcı" yaz
                ),
              ),
            );
          }),
    );
  }

  // BOŞ DURUM TASARIMI
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("Henüz bir mesajın yok.",
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
} // Sınıfın en sonundaki kapatma parantezi
