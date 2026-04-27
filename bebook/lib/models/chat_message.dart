class ChatMessage {
  final int id;
  final int senderId;
  final int receiverId;
  final int bookId;
  final String messageText;
  final DateTime createdAt;
  final bool isRead; // MAVİ TİK İÇİN GEREKLİ ALAN

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.bookId,
    required this.messageText,
    required this.createdAt,
    required this.isRead, // CONSTRUCTOR'A EKLENDİ
  });

  // BACKEND'DEN GELEN VERİYİ MODELLEMEK İÇİN BU FONKSİYON ŞART:
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? 0,
      senderId: json['sender_id'] ?? 0,
      receiverId: json['receiver_id'] ?? 0,
      bookId: json['book_id'] ?? 0,
      messageText: json['message_text'] ?? "",
      // Tarih verisini DateTime objesine çeviriyoruz
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      // İŞTE MAVİ TİKİ BELİRLEYEN SATIR:
      isRead: json['is_read'] == true || json['is_read'] == 1,
    );
  }
}