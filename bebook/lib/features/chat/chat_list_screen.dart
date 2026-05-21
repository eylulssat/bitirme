import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/chat_detail_screen.dart';
import '../../services/api_service.dart';

class ChatListScreen extends StatefulWidget {
  final int myId;
  const ChatListScreen({super.key, required this.myId});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<dynamic> chatList = [];
  bool isLoading = true;

  @override
void initState() {
  super.initState();
  // Bu iki ├ğa─ş─▒rma da initState i├ğinde, super.initState'den sonra olmal─▒
  _markMyMessagesAsDelivered(); 
  _fetchChatList(); // <-- Buras─▒ k─▒rm─▒z─▒ysa ├╝stteki fonksiyonun parantezlerini kontrol et
}

// BU FONKS─░YON initState'in DI┼ŞINDA OLMALI (Hemen alt─▒na ekleyebilirsin)
Future<void> _markMyMessagesAsDelivered() async {
  try {
    await http.put(
      Uri.parse("http://192.168.1.5:8000/mark_as_delivered/${widget.myId}")
    ).timeout(const Duration(seconds: 10));
  } catch (e) {
    print("Hata: $e");
  }
}
// 2. L─░STEY─░ ├çEKEN FONKS─░YON (BU EKS─░K OLDU─ŞU ─░├ç─░N KIRMIZI YANIYOR OLAB─░L─░R)
  Future<void> _fetchChatList() async {
    try {
      final response = await http
          .get(Uri.parse("http://192.168.1.5:8000/chats/${widget.myId}"))
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
      print("Liste ├ğekme hatas─▒: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // 2. S─░LME YAPAN FONKS─░YON
  Future<void> deleteChat(int otherId, int bookId) async {
    try {
      final response = await http.delete(
        Uri.parse(
            "http://192.168.1.5:8000/chats/delete?my_id=${widget.myId}&other_id=$otherId&book_id=$bookId"),
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
      print("Silme hatas─▒: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6C63FF);

    // --- BURASI YEN─░: G─░R─░┼Ş KONTROL├£ K─░L─░D─░ ---
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
                  "Giri┼ş Yapmal─▒s─▒n─▒z",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Mesajlar─▒n─▒z─▒ g├Ârmek i├ğin l├╝tfen ├Ânce hesab─▒n─▒za giri┼ş yap─▒n.",
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
                    // Ana sayfaya dön ve profil sekmesine geç
                    Navigator.pop(context);
                  },
                  child: const Text("Ana Sayfaya Dön",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }
    // --- K─░L─░T KISMI BURADA B─░T─░YOR ---

    // SEN─░N MEVCUT KODUN (H─░├ç DOKUNULMADI):
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("Mesajlar─▒m",
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

  // MESAJ KARTINI AYRI B─░R WIDGET OLARAK SINIF ─░├ç─░NDE TANIMLADIK
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
                  "http://192.168.1.5:8000/${chat['profile_image'].toString().replaceAll('\\', '/')}")
              : null,
          child: (chat['profile_image'] == null ||
                  chat['profile_image'].toString().isEmpty)
              ? Text(
                  // G├£VENL─░ KONTROL:
                  // E─şer receiver_name varsa ve bo┼ş de─şilse ilk harfini al,
                  // yoksa '?' koy ki uygulama ├ğ├Âkmesin.
                  (chat['receiver_name'] != null &&
                          chat['receiver_name'].toString().isNotEmpty)
                      ? chat['receiver_name'][0].toUpperCase()
                      : "?",
                  style: TextStyle(
                      color: primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Text(
            // chat['receiver_name'] null gelse bile uygulama ├ğ├Âkmez, 'Bilinmeyen' yazar.
            (chat['receiver_name'] ?? "Bilinmeyen Kullan─▒c─▒").toString(),
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
                "­şôÜ ${chat['book_title']}",
                style: TextStyle(
                    color: primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              chat['last_message'] ?? "Hen├╝z mesaj yok...",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min, // Sadece ikonlar kadar yer kaplar
          children: [
            if (chat['unread_count'] != null && chat['unread_count'] > 0)
              Container(
                margin: const EdgeInsets.only(
                    right: 8), // Silme butonuyla aras─▒na mesafe
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor, // Temandaki ana mor renk
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  chat['unread_count'].toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 20),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Sohbeti Sil"),
                    content: const Text(
                        "Bu sohbeti silmek istedi─şinize emin misiniz?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("─░ptal"),
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
        onTap: () async {
          // 1. ADIM: Okundu i┼şlemini BURADAN S─░LD─░K.
          // ├ç├╝nk├╝ ChatDetailScreen a├ğ─▒l─▒nca zaten initState i├ğinde bunu yapacak.

          // 2. ADIM: Sadece sayfaya y├Ânlendiriyoruz
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                receiverId: chat['receiver_id'],
                receiverName: chat['receiver_name'] ?? "Kullan─▒c─▒",
                receiverImage: chat['profile_image'],
                bookTitle: chat['book_title'],
                bookId: chat['book_id'],
                myId: widget.myId,
                myName: "Ben",
              ),
            ),
          );

          // 3. ADIM: Sohbetten geri d├Ân├╝ld├╝─ş├╝nde listeyi yenile (Okunmam─▒┼ş mesaj say─▒s─▒ g├╝ncellensin diye)
          _fetchChatList();
        },
      ),
    );
  }

  // BO┼Ş DURUM TASARIMI
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("Hen├╝z bir mesaj─▒n yok.",
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
} // S─▒n─▒f─▒n en sonundaki kapatma parantezi