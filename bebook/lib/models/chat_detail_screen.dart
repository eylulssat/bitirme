import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'chat_message.dart';
import '../services/api_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final int receiverId;
  final String receiverName;
  final String? receiverImage;
  final String bookTitle;
  final int bookId;
  // GENEL OLMASI İÇİN BU İKİ SATIRI EKLEDİK:
  final int myId;
  final String myName;

  const ChatDetailScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.receiverImage,
    required this.bookTitle,
    required this.bookId,
    required this.myId, // Dışarıdan gelecek
    required this.myName, // Dışarıdan gelecek
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> messages = [];
  bool _isLoading = true;
  Timer? _timer;

  // ARTIK BURADA SABİT ID YOK, widget.myId KULLANACAĞIZ

  @override
  void initState() {
    super.initState();

    // Burada ismi aşağıdakine göre güncelledik:
    _markAllAsRead();

    _fetchMessages();

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchMessages();
    });
  }

// Fonksiyonun ismi bu olduğu için yukarıda da aynısını çağırmalısın
  Future<void> _markAllAsRead() async {
    await ApiService.markMessagesAsRead(
        widget.myId, widget.receiverId, widget.bookId);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    try {
      // BURADAKİ ApiService.markMessagesAsRead KISMINI SİLDİK!

      final response = await http
          .get(
            Uri.parse(
                "http://192.168.67.144:8000/messages/${widget.myId}/${widget.receiverId}/${widget.bookId}"),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = jsonDecode(response.body);
        if (decodedData.isNotEmpty) {
          print(
              "Gelen ilk mesajın okundu durumu: ${decodedData.last['is_read']}");
        }
        if (mounted) {
          setState(() {
            messages = decodedData.map((m) => ChatMessage.fromJson(m)).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Hata oluştu: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final String text = _messageController.text;

    setState(() {
      messages.add(ChatMessage(
        id: 0,
        senderId: widget.myId,
        receiverId: widget.receiverId,
        bookId: widget.bookId,
        messageText: text,
        createdAt: DateTime.now(),
        isRead: false,
      ));
      _messageController.clear();
    });

// WidgetsBinding kullanarak listenin güncellendiğinden emin olup sonra kaydırıyoruz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    try {
      final response = await http.post(
        Uri.parse("http://192.168.67.144:8000/messages/send"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "sender_id": widget.myId,
          "receiver_id": widget.receiverId,
          "book_id": widget.bookId,
          "message_text": text,
        }),
      );

      if (response.statusCode == 200) {
        // MESAJ BAŞARIYLA GİTTİĞİNDE:
        // Listeyi hemen tekrar çekiyoruz ki veritabanındaki
        // gerçek zaman damgası ve mesaj ID'si ekrana gelsin.
        _fetchMessages();
      }

      if (!mounted) return;
    } catch (e) {
      print("Gönderim hatası: $e");
    }
  }

  Widget _buildAvatar(String name, bool isMe, String? imageUrl) {
    // imageUrl parametresi ekledik
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 12 : 0,
        right: isMe ? 0 : 12,
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundColor:
            isMe ? const Color(0xFF6C63FF).withOpacity(0.2) : Colors.grey[300],
        // BURAYI GÜNCELLEDİK: Fotoğraf varsa onu göster, yoksa harf göster
        backgroundImage: (!isMe && imageUrl != null && imageUrl.isNotEmpty)
            ? NetworkImage(
                "http://192.168.67.144:8000${imageUrl.startsWith('/') ? imageUrl : '/$imageUrl'}")
            : null,
        child: (!isMe && imageUrl != null && imageUrl.isNotEmpty)
            ? null // Fotoğraf varsa harfe gerek yok
            : Text(
                name.isNotEmpty ? name[0].toUpperCase() : "?",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isMe ? const Color(0xFF6C63FF) : Colors.black54,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6C63FF);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: false, // Fotoğraf gelince sola yaslı durması daha şık olur
        title: Row(
          children: [
            // --- FOTOĞRAF BURAYA EKLENDİ ---
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[200],
              backgroundImage: (widget.receiverImage != null &&
                      widget.receiverImage!.isNotEmpty)
                  ? NetworkImage(
                      "http://192.168.67.144:8000/${widget.receiverImage!.replaceAll(r'\', '/')}")
                  : null,
              child: (widget.receiverImage == null ||
                      widget.receiverImage!.isEmpty)
                  ? Text(widget.receiverName.isNotEmpty
                      ? widget.receiverName[0].toUpperCase()
                      : "?")
                  : null,
            ),
            const SizedBox(width: 12), // Fotoğraf ile yazı arasındaki boşluk

            // İsim ve Kitap başlığını içeren sütun
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.bookTitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      // Mesajı model tipine (ChatMessage) dönüştürerek alıyoruz
                      final msg = messages[index] as ChatMessage;

                      // Gönderen ben miyim kontrolü (Model içindeki senderId ile)
                      final bool isMe = msg.senderId == widget.myId;

                      // Mavi tik kontrolü (Model içindeki isRead ile)
                      final bool isRead = msg.isRead;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMe)
                              _buildAvatar(widget.receiverName, false,
                                  widget.receiverImage),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.65,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isMe ? primaryColor : Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(18).copyWith(
                                        bottomLeft:
                                            Radius.circular(isMe ? 18 : 0),
                                        bottomRight:
                                            Radius.circular(isMe ? 0 : 18),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        )
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isMe
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Mesaj Metni
                                        Text(
                                          msg.messageText,
                                          style: TextStyle(
                                            color: isMe
                                                ? Colors.white
                                                : Colors.black87,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        // Saat ve Tik Simgesi (Yan Yana)
                                        // 351. Satırdan itibaren Row( mainAxisSize: ... ) kısmını silip bunu koy:

                                        Wrap(
                                          alignment: WrapAlignment.end,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            // Saat bilgisi
                                            Text(
                                              "${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}",
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isMe
                                                    ? Colors.white70
                                                    : Colors.black45,
                                              ),
                                            ),
                                            // Eğer mesaj benden gittiyse TİK göster
                                            if (isMe) ...[
                                              const SizedBox(width: 4),
                                              Icon(
                                                // MANTIK: Okunduysa çift tik (done_all), okunmadıysa tek tik (done)
                                                msg.isRead
                                                    ? Icons.done_all
                                                    : Icons.done,
                                                size: 15,
                                                // MANTIK: Okunduysa canlı bir mavi, okunmadıysa sönük bir beyaz/gri
                                                color: msg.isRead
                                                    ? const Color(
                                                        0xFF00FF88) // Neon Yeşil
                                                    : Colors.white38,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                _buildInputArea(primaryColor),
              ],
            ),
    );
  }

  Widget _buildInputArea(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: "Mesaj yaz...",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: primaryColor),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
