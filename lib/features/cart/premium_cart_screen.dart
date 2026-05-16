import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/book_card.dart';
import '../../models/book_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 💎 Premium Sepet Ekranı - Glassmorphism & Modern Design
class PremiumCartScreen extends StatefulWidget {
  final VoidCallback onDiscoverPressed;

  const PremiumCartScreen({super.key, required this.onDiscoverPressed});

  @override
  State<PremiumCartScreen> createState() => _PremiumCartScreenState();
}

class _PremiumCartScreenState extends State<PremiumCartScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isWaitingForPayment = false;
  bool _isAgreedToTerms = false;
  int? lastOrderId;
  int? _currentUserId;
  List<Book> _userCart = [];
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserCart();
    logoutNotifier.addListener(_handleLogout);
    
    // Fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _fadeController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    logoutNotifier.removeListener(_handleLogout);
    super.dispose();
  }

  Future<void> _loadUserCart() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    setState(() {
      _currentUserId = userId;
      _userCart = CartManager.getCart(userId);
    });
  }

  void _handleLogout() {
    if (logoutNotifier.value == true) {
      if (mounted) {
        setState(() {
          _userCart = [];
          _currentUserId = null;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed && _isWaitingForPayment) {
      final statusResult = await ApiService.getOrderStatus(lastOrderId);

      if (statusResult['status'] == 'SUCCESS') {
        setState(() {
          CartManager.clearCart(_currentUserId);
          _userCart = [];
          _isWaitingForPayment = false;
        });

        _showSnackBar("Sipariş işleminiz tamamlandı! 🎉", AppTheme.successGreen);
      } else {
        setState(() => _isWaitingForPayment = false);
      }
    }
  }

  double _calculateTotal() {
    return _userCart.fold(0, (sum, book) => sum + (book.price));
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      "Mesafeli Satış Sözleşmesi",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    "1. TARAFLAR: İşbu sözleşme BEBOOK üzerinden alışveriş yapan kullanıcı ile satıcı arasındadır.\n\n"
                    "2. KONU: Alıcının satıcıya ait web sitesi üzerinden elektronik ortamda siparişini verdiği ürünün satışı ve teslimi ile ilgili hak ve yükümlülükleri kapsar.\n\n"
                    "3. TESLİMAT: Ürün, alıcının belirttiği adrese güvenli bir şekilde gönderilecektir.\n\n"
                    "4. CAYMA HAKKI: Dijital içeriklerde ve özel basımlarda cayma hakkı sınırlıdır.\n\n"
                    "Bu metin BEBOOK projesi kapsamında test amaçlı oluşturulmuştur.",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryIndigo,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Anladım",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _completePayment() async {
    if (_userCart.isEmpty) return;

    if (_currentUserId == null) {
      _showSnackBar("Ödeme yapmak için giriş yapmalısınız", AppTheme.warningAmber);
      return;
    }

    HapticFeedback.mediumImpact();
    _isAgreedToTerms = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            "Teslimat Bilgileri",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Name field
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: "Ad Soyad",
                        prefixIcon: const Icon(Icons.person_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppTheme.primaryIndigo, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Address field
                    TextField(
                      controller: _addressController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "Teslimat Adresi",
                        prefixIcon: const Icon(Icons.location_on_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppTheme.primaryIndigo, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Terms checkbox
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.neutralLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _isAgreedToTerms,
                            activeColor: AppTheme.primaryIndigo,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            onChanged: (value) {
                              setDialogState(() => _isAgreedToTerms = value!);
                            },
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: _showTermsDialog,
                              child: Text(
                                "Mesafeli Satış Sözleşmesi'ni okudum, onaylıyorum.",
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  decoration: TextDecoration.underline,
                                  color: AppTheme.primaryIndigo,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: BorderSide(color: AppTheme.neutralDark),
                            ),
                            child: Text(
                              "İptal",
                              style: TextStyle(
                                color: AppTheme.neutralDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isAgreedToTerms
                                  ? AppTheme.primaryIndigo
                                  : AppTheme.neutralMedium,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _isAgreedToTerms
                                ? () {
                                    if (_nameController.text.isNotEmpty &&
                                        _addressController.text.isNotEmpty) {
                                      Navigator.pop(context);
                                      _processPaymentRequest();
                                    } else {
                                      _showSnackBar(
                                        "Lütfen tüm alanları doldurun",
                                        AppTheme.warningAmber,
                                      );
                                    }
                                  }
                                : null,
                            child: const Text(
                              "Ödemeye Geç",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _processPaymentRequest() async {
    List<int> ids = _userCart.map((b) => b.id).toList();
    double total = _calculateTotal();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: AppTheme.primaryIndigo,
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                "Ödeme hazırlanıyor...",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final result = await ApiService.makeBulkPayment(
        userId: _currentUserId!,
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
        _showSnackBar(
          "Hata: ${result['errorMessage'] ?? result['message']}",
          AppTheme.errorRed,
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackBar("Ödeme hatası: $e", AppTheme.errorRed);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _userCart = CartManager.getCart(_currentUserId);

    return Scaffold(
      backgroundColor: AppTheme.neutralLight,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Animated background
          _buildAnimatedBackground(),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildPremiumHeader(),
                Expanded(
                  child: _userCart.isEmpty
                      ? _buildEmptyState()
                      : _buildCartItems(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.neutralLight,
              AppTheme.primaryIndigo.withOpacity(0.02),
              AppTheme.accentOrange.withOpacity(0.02),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.8),
                Colors.white.withOpacity(0.6),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryIndigo.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shopping_bag_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Sepetim",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_userCart.isNotEmpty)
                      Text(
                        "${_userCart.length} ürün",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.neutralDark,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryIndigo.withOpacity(0.1),
                      AppTheme.accentOrange.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shopping_cart_outlined,
                  size: 100,
                  color: AppTheme.primaryIndigo,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Sepetiniz henüz boş",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Kitap keşfetmeye başlayın!",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.neutralDark,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryIndigo.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    widget.onDiscoverPressed();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryIndigo,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.explore_rounded, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(
                        "Kitap Keşfet",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartItems() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: _userCart.length,
            itemBuilder: (context, index) {
              final book = _userCart[index];
              return _buildCartItem(book, index);
            },
          ),
        ),
        _buildBottomSection(),
      ],
    );
  }

  Widget _buildCartItem(Book book, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => HapticFeedback.lightImpact(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Book image
                  Hero(
                    tag: 'cart_book_${book.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        book.imagePath.isNotEmpty
                            ? book.imagePath
                            : "https://via.placeholder.com/150",
                        width: 70,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 70,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryIndigo.withOpacity(0.2),
                                AppTheme.accentCyan.withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.book, size: 40),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Book info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book.author,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.neutralDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${book.price.toStringAsFixed(0)} ₺",
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Delete button
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: AppTheme.errorRed,
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      setState(() {
                        CartManager.removeFromCart(_currentUserId, book.id);
                        _userCart = CartManager.getCart(_currentUserId);
                      });
                      _showSnackBar("Sepetten çıkarıldı", AppTheme.neutralDark);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Total
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryIndigo.withOpacity(0.1),
                        AppTheme.accentCyan.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Toplam Tutar",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppTheme.primaryGradient.createShader(bounds),
                        child: Text(
                          "${_calculateTotal().toStringAsFixed(2)} ₺",
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Payment button
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentOrange.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _completePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentOrange,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.payment_rounded, color: Colors.white),
                          const SizedBox(width: 12),
                          Text(
                            "ÖDEMEYİ TAMAMLA",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
