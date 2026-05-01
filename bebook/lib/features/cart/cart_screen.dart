import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/book_card.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/book_model.dart';

// Not: Book modelinin bu dosyada veya import edilen yerde tanımlı olduğu varsayılmıştır.
// Eğer hata alırsan Book modelini import ettiğinden emin ol.

class CartScreen extends StatefulWidget {
  final VoidCallback onDiscoverPressed;
  final VoidCallback? onCartUpdated;
  final int myId;

  const CartScreen({
    super.key,
    required this.onDiscoverPressed,
    this.onCartUpdated,
    required this.myId,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with WidgetsBindingObserver {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isWaitingForPayment = false;
  bool _isAgreedToTerms = false;
  int? lastOrderId;
  bool _isLoading = true;
  List<Book> cartBooks = []; // Liste tanımı

  @override
void initState() {
  super.initState();

  print("🔥 CART SCREEN MY ID: ${widget.myId}");

  WidgetsBinding.instance.addObserver(this);
  _fetchCartFromServer();
}

  void _fetchCartItems() async {
  final items = await ApiService.getCartItems(widget.myId);

  print("BOOK LİST:");
  for (var b in items) {
    print(b);
  }

  setState(() {
    cartBooks = items.map((json) => Book.fromJson(json)).toList();
  });
}

  Future<void> _fetchCartFromServer() async {
    setState(() => _isLoading = true);
    try {
      print("DEBUG: Sepet verisi isteniyor (User ID: ${widget.myId})...");
      final dynamic responseData = await ApiService.getCartItems(widget.myId);
      print("DEBUG: Backend'den gelen ham veri: $responseData");

      setState(() {
        cartBooks =
            (responseData as List).map((item) => Book.fromJson(item)).toList();
        print(
            "DEBUG: Dönüştürme başarılı. Sepetteki kitap sayısı: ${cartBooks.length}");
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("HATA: Sepet çekilirken bir sorun oluştu: $e");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed && _isWaitingForPayment) {
      final statusResult = await ApiService.getOrderStatus(lastOrderId);

      if (statusResult['status'] == 'SUCCESS') {
        setState(() {
          cartBooks.clear();
          _isWaitingForPayment = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sipariş işleminiz tamamlandı."),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isWaitingForPayment = false;
        });
      }
    }
  }

  double _calculateTotal() {
    double total = 0;
    for (var book in cartBooks) {
      total += double.tryParse(book.price.toString()) ?? 0;
    }
    return total;
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Mesafeli Satış Sözleşmesi"),
        content: const SingleChildScrollView(
          child: Text(
              "1. TARAFLAR: İşbu sözleşme BEBOOK üzerinden alışveriş yapan kullanıcı ile satıcı arasındadır.\n\n"
              "2. KONU: Alıcının satıcıya ait web sitesi üzerinden elektronik ortamda siparişini verdiği ürünün satışı ve teslimi ile ilgili hak ve yükümlülükleri kapsar.\n\n"
              "3. TESLİMAT: Ürün, alıcının belirttiği adrese güvenli bir şekilde gönderilecektir.\n\n"
              "4. CAYMA HAKKI: Dijital içeriklerde ve özel basımlarda cayma hakkı sınırlıdır.\n\n"
              "Bu metin BEBOOK projesi kapsamında test amaçlı oluşturulmuştur."),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Anladım")),
        ],
      ),
    );
  }

  void _completePayment(Color primaryColor) async {
    if (cartBooks.isEmpty) return;
    _isAgreedToTerms = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Teslimat Bilgileri",
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Ad Soyad",
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Teslimat Adresi",
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Checkbox(
                        value: _isAgreedToTerms,
                        activeColor: primaryColor,
                        onChanged: (value) {
                          setDialogState(() {
                            _isAgreedToTerms = value!;
                          });
                        },
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: _showTermsDialog,
                          child: const Text(
                            "Mesafeli Satış Sözleşmesi'ni okudum, onaylıyorum.",
                            style: TextStyle(
                                fontSize: 12,
                                decoration: TextDecoration.underline),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("İptal")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isAgreedToTerms ? primaryColor : Colors.grey,
                ),
                onPressed: _isAgreedToTerms
                    ? () {
                        if (_nameController.text.isNotEmpty &&
                            _addressController.text.isNotEmpty) {
                          Navigator.pop(context);
                          _processPaymentRequest(primaryColor);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Lütfen tüm alanları doldurun.")),
                          );
                        }
                      }
                    : null,
                child: const Text("Ödemeye Geç",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _processPaymentRequest(Color primaryColor) async {
    List<int> ids =
        cartBooks.map((b) => int.parse(b.bookId.toString())).toList();
    List<int> ids = cartBooks.map((b) => b.id).toList();
    double total = _calculateTotal();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await ApiService.makeBulkPayment(
        userId: widget.myId,
        bookIds: ids,
        totalPrice: total,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (result['status'] == 'success' || result['status'] == 'None') {
        lastOrderId = result['orderId'];
        String? paymentUrl = result['paymentPageUrl'];

        if (paymentUrl != null && paymentUrl.isNotEmpty) {
          final Uri url = Uri.parse(paymentUrl);
          _isWaitingForPayment = true;
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("Hata: ${result['errorMessage'] ?? result['message']}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Ödeme hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6C63FF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Sepetim",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartBooks.isEmpty
              ? _buildEmptyState(primaryColor)
              : _buildCartItems(primaryColor),
    );
  }

  Widget _buildEmptyState(Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 100, color: primaryColor),
            const SizedBox(height: 30),
            const Text("Sepetiniz henüz boş",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                onPressed: widget.onDiscoverPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text("Kitap Keşfet",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItems(Color primaryColor) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: cartBooks.length,
            itemBuilder: (context, index) {
              final book = cartBooks[index];
              return Card(
                // ValueKey silme sonrası widget'ların karışmasını kesinlikle önler
                key: ValueKey(book.bookId),
                margin: const EdgeInsets.only(bottom: 15),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      (book.imageUrl != null &&
                              book.imageUrl!.startsWith('http'))
                          ? book.imageUrl!
                          : "http://192.168.67.144:8000/uploads/${book.imageUrl}",
                      width: 50,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.book, size: 40),
                      book.imagePath.isNotEmpty ? book.imagePath : "https://via.placeholder.com/150",
                      width: 50, height: 70, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.book, size: 40),
                    ),
                  ),
                  title: Text(book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${book.price} TL",
                      style: TextStyle(
                          color: primaryColor, fontWeight: FontWeight.bold)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      // 1. Önce sunucudan sil
                      bool silindi = await ApiService.removeFromCart(
                          widget.myId, book.bookId);

                      if (silindi) {
                        // 2. Sunucudan silindiyse, listeyi backend ile TAM SENKRONİZE ET
                        // Sadece removeAt değil, güncel listeyi çekmek en güvenli yoldur.
                        await _fetchCartFromServer();

                        // 3. Alt bardaki sayacı vs. güncellemek için üst widget'a haber ver
                        if (widget.onCartUpdated != null) {
                          widget.onCartUpdated!();
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Ürün sepetten çıkarıldı"),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Silme işlemi başarısız oldu!"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
        _buildBottomSection(primaryColor),
      ],
    );
  }

  Widget _buildBottomSection(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Toplam Tutar",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                Text("${_calculateTotal().toStringAsFixed(2)} TL",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => _completePayment(primaryColor),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("ÖDEMEYİ TAMAMLA",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
