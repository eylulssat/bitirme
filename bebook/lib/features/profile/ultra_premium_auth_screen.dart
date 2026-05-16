import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'forgot_password_screen.dart';

/// 💎 Ultra Premium Auth Screen - Next Level Design
class UltraPremiumAuthScreen extends StatefulWidget {
  final bool isLogin;

  const UltraPremiumAuthScreen({super.key, this.isLogin = true});

  @override
  State<UltraPremiumAuthScreen> createState() => _UltraPremiumAuthScreenState();
}

class _UltraPremiumAuthScreenState extends State<UltraPremiumAuthScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _isObscure = true;
  bool _isLoading = false;

  late AnimationController _mainController;
  late AnimationController _backgroundController;
  late AnimationController _formController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _backgroundAnimation;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _selectedUniversity;
  String? _selectedDepartment;

  final List<String> _universities = [
    'Zonguldak Bülent Ecevit Üniversitesi',
    'İstanbul Teknik Üniversitesi',
    'Orta Doğu Teknik Üniversitesi',
    'Boğaziçi Üniversitesi',
    'Hacettepe Üniversitesi',
    'Bilkent Üniversitesi',
    'Koç Üniversitesi',
    'Sabancı Üniversitesi',
    'Diğer'
  ];

  final List<String> _departments = [
    'Bilgisayar Mühendisliği',
    'Elektrik-Elektronik Mühendisliği',
    'Makine Mühendisliği',
    'Endüstri Mühendisliği',
    'İktisat',
    'İşletme',
    'Tıp',
    'Diş Hekimliği',
    'Eczacılık',
    'Psikoloji',
    'İstatistik',
    'Matematik',
    'Fizik',
    'Kimya',
    'Yönetim Bilişim Sistemleri',
    'Diğer'
  ];

  @override
  void initState() {
    super.initState();
    _isLogin = widget.isLogin;

    // Main animation controller
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Background animation controller
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    // Form animation controller
    _formController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: Curves.elasticOut,
    ));

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_backgroundController);

    _mainController.forward();
    _formController.forward();
    _backgroundController.repeat();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _backgroundController.dispose();
    _formController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    const String apiUrl = "http://10.108.206.156:8000/login";

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text.trim(),
          "password": _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', data['user_id']);
        await prefs.setString('user_email', data['user_email']);
        await prefs.setString('university', data['university']);
        await prefs.setString('department', data['department']);
        await prefs.setBool('is_logged_in', true);

        if (mounted) {
          HapticFeedback.heavyImpact();
          _showSnackBar("Hoş geldin! 🎉", AppTheme.successGreen);
          
          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.pop(context, {
            "user_id": data['user_id'],
            "user_email": data['user_email'],
            "university": data['university'],
            "department": data['department'],
          });
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showSnackBar(
          errorData['detail'] ?? "E-posta veya şifre hatalı!",
          AppTheme.errorRed,
        );
      }
    } catch (e) {
      _showSnackBar("Bağlantı hatası: Sunucuya erişilemiyor.", AppTheme.errorRed);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignup() async {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    bool success = await ApiService.signup(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      university: _selectedUniversity ?? "",
      department: _selectedDepartment ?? "",
    );

    setState(() => _isLoading = false);

    if (success) {
      HapticFeedback.heavyImpact();
      _showSnackBar("Başarıyla üye oldun! 🎉", AppTheme.successGreen);
      
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _isLogin = true;
        _formController.reset();
        _formController.forward();
      });
    } else {
      _showSnackBar(
        "Kayıt başarısız. Bu e-posta zaten kullanımda olabilir.",
        AppTheme.errorRed,
      );
    }
  }

  void _toggleMode() {
    HapticFeedback.lightImpact();
    setState(() {
      _isLogin = !_isLogin;
      _formController.reset();
      _formController.forward();
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == AppTheme.successGreen ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutralBlack,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Ultra Dynamic Background
          _buildUltraDynamicBackground(),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        const SizedBox(height: 60),
                        _buildUltraHeader(),
                        const SizedBox(height: 60),
                        _buildUltraForm(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Premium Back Button
          _buildPremiumBackButton(),
        ],
      ),
    );
  }

  Widget _buildUltraDynamicBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryIndigo.withOpacity(0.9),
                AppTheme.primaryIndigoLight.withOpacity(0.8),
                AppTheme.accentCyan.withOpacity(0.7),
                AppTheme.accentOrange.withOpacity(0.6),
                AppTheme.accentPink.withOpacity(0.8),
              ],
              stops: [
                0.0,
                0.25 + (_backgroundAnimation.value * 0.1),
                0.5 + (_backgroundAnimation.value * 0.15),
                0.75 + (_backgroundAnimation.value * 0.1),
                1.0,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Premium floating elements - more sophisticated
              ...List.generate(8, (index) {
                final offset = _backgroundAnimation.value * 2 * 3.14159;
                final size = 15.0 + (index * 8);
                final opacity = 0.05 + (index % 3) * 0.03;
                
                return Positioned(
                  left: 30 + (index * 80) + (50 * (index % 2 == 0 ? 1 : -1) * _backgroundAnimation.value),
                  top: 80 + (index * 90) + (60 * (index % 2 == 0 ? 1 : -1) * _backgroundAnimation.value),
                  child: Transform.rotate(
                    angle: offset + (index * 0.8),
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(size * 0.3),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(opacity),
                            Colors.white.withOpacity(opacity * 0.5),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1),
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              
              // Premium mesh gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.5,
                    colors: [
                      Colors.white.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              
              // Bottom mesh gradient
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.bottomLeft,
                    radius: 1.2,
                    colors: [
                      AppTheme.accentOrange.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPremiumBackButton() {
    return Positioned(
      top: 50,
      left: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUltraHeader() {
    return Column(
      children: [
        // Premium Animated Logo with glassmorphism
        ScaleTransition(
          scale: _scaleAnimation,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.25),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: AppTheme.primaryIndigo.withOpacity(0.3),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Colors.white,
                      AppTheme.accentOrange.withOpacity(0.8),
                      AppTheme.accentPink.withOpacity(0.8),
                    ],
                  ).createShader(bounds),
                  child: Icon(
                    _isLogin ? Icons.lock_person_rounded : Icons.person_add_alt_1_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        
        // Premium Animated Title with gradient text
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.white.withOpacity(0.9),
              AppTheme.accentOrange.withOpacity(0.8),
            ],
          ).createShader(bounds),
          child: Text(
            _isLogin ? "Tekrar Hoş Geldin!" : "Aramıza Katıl!",
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -1,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        
        // Premium subtitle with better typography
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            _isLogin
                ? "Hesabına giriş yap ve kitap dünyasına devam et"
                : "Yeni bir hesap oluştur ve keşfetmeye başla",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.85),
              height: 1.6,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildUltraForm() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.12),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                  BoxShadow(
                    color: AppTheme.primaryIndigo.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Email Field
                    _buildUltraTextField(
                      "E-posta Adresin",
                      Icons.alternate_email_rounded,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),

                    // Password Field
                    _buildUltraTextField(
                      "Şifren",
                      Icons.lock_outline_rounded,
                      controller: _passwordController,
                      isPassword: true,
                    ),

                    // Forgot Password (Login only)
                    if (_isLogin) ...[
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white.withOpacity(0.1),
                          ),
                          child: TextButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: Text(
                              "Şifremi Unuttum",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    // University & Department (Signup only)
                    if (!_isLogin) ...[
                      const SizedBox(height: 24),
                      _buildUltraDropdown(
                        "Üniversiten",
                        Icons.school_rounded,
                        _universities,
                        _selectedUniversity,
                        (val) => setState(() => _selectedUniversity = val),
                      ),
                      const SizedBox(height: 24),
                      _buildUltraDropdown(
                        "Bölümün",
                        Icons.auto_stories_rounded,
                        _departments,
                        _selectedDepartment,
                        (val) => setState(() => _selectedDepartment = val),
                      ),
                    ],

                    const SizedBox(height: 40),

                    // Submit Button
                    _buildUltraSubmitButton(),

                    const SizedBox(height: 32),

                    // Toggle Mode
                    _buildToggleMode(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUltraTextField(
    String label,
    IconData icon, {
    required TextEditingController controller,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.08),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && _isObscure,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        validator: (v) => (v == null || v.isEmpty) ? "Bu alan gereklidir" : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentOrange.withOpacity(0.3),
                  AppTheme.accentPink.withOpacity(0.3),
                ],
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white.withOpacity(0.9),
              size: 20,
            ),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: Icon(
                      _isObscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      color: Colors.white.withOpacity(0.8),
                      size: 20,
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isObscure = !_isObscure);
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        ),
      ),
    );
  }

  Widget _buildUltraDropdown(
    String label,
    IconData icon,
    List<String> items,
    String? value,
    Function(String?) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.08),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        dropdownColor: AppTheme.primaryIndigo.withOpacity(0.95),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentCyan.withOpacity(0.3),
                  AppTheme.accentPink.withOpacity(0.3),
                ],
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white.withOpacity(0.9),
              size: 20,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        ),
        items: items.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (v) => (v == null) ? "Lütfen seçim yapın" : null,
        isExpanded: true,
        icon: Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withOpacity(0.1),
          ),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white.withOpacity(0.8),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildUltraSubmitButton() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentOrange,
            AppTheme.accentPink,
            AppTheme.accentCyan.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentOrange.withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppTheme.accentPink.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : () {
                HapticFeedback.mediumImpact();
                if (_formKey.currentState!.validate()) {
                  if (_isLogin) {
                    _handleLogin();
                  } else {
                    _handleSignup();
                  }
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: _isLoading
            ? Container(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: Icon(
                      _isLogin ? Icons.login_rounded : Icons.person_add_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _isLogin ? "Giriş Yap" : "Üye Ol",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildToggleMode() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _isLogin ? "Hesabın yok mu?" : "Zaten hesabın var mı?",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentOrange.withOpacity(0.3),
                  AppTheme.accentPink.withOpacity(0.3),
                ],
              ),
            ),
            child: TextButton(
              onPressed: _toggleMode,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                _isLogin ? "Üye Ol" : "Giriş Yap",
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
    );
  }
}