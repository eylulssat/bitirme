class ChatMessage {
  final int? id;
  final int senderId;
  final int receiverId;
  final int bookId; // <-- Burayı eklediğinden emin ol
  final String messageText;
  final DateTime createdAt;
  final bool isRead;

  ChatMessage({
    this.id,
    required this.senderId,
    required this.receiverId,
    required this.bookId, // <-- Burayı da ekle
    required this.messageText,
    required this.createdAt,
    required this.isRead,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderId: json['sender_id'] ?? 0,
      receiverId: json['receiver_id'] ?? 0,
      bookId: json['book_id'] ?? 0, // <-- Backend'den gelen book_id
      messageText: json['message_text'] ?? "",
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      isRead: json['is_read'] == true || json['is_read'] == 1,
    );
  }
}