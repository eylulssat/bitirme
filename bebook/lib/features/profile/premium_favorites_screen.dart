import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../models/book_model.dart';
import '../../services/api_service.dart';
import '../../widgets/premium_book_card.dart';
import '../../widgets/book_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 💎 Premium Favoriler Ekranı - Modern & Animated
class PremiumFavoritesScreen extends StatefulWidget {
  const PremiumFavoritesScreen({super.key});

  @override
  State<PremiumFavoritesScreen> createState() => _PremiumFavoritesScreenState();
}

class _PremiumFavoritesScreenState extends State<PremiumFavoritesScreen>
    with SingleTickerProviderStateMixin {
  List<Book> _favoriteBooks = [];
  bool _isLoading = true;
  int? _currentUserId;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadFavorites();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();

    // Favori değişikliklerini dinle
    favoriteChangeNotifier.addListener(_onFavoriteChanged);
    logoutNotifier.addListener(_handleLogout);
  }

  @override
  void dispose() {
    _controller.dispose();
    favoriteChangeNotifier.removeListener(_onFavoriteChanged);
    logoutNotifier.removeListener(_handleLogout);
    super.dispose();
  }

  void _onFavoriteChanged() {
    _loadFavorites();
  }

  void _handleLogout() {
    if (logoutNotifier.value == true) {
      if (mounted) {
        setState(() {
          _favoriteBooks = [];
          _currentUserId = null;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId != null) {
        setState(() => _currentUserId = userId);

        final rawData = await ApiService.getFavorites(userId);
        final favorites = rawData.map((json) => Book.fromJson(json)).toList();

        setState(() {
          _favoriteBooks = favorites;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutralLight,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Animated Background
          _buildAnimatedBackground(),

          // Content
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Premium Header
                _buildPremiumHeader(),

                // Content
                _isLoading
                    ? _buildLoadingState()
                    : _currentUserId == null
                        ? _buildLoginRequiredState()
                        : _favoriteBooks.isEmpty
                            ? _buildEmptyState()
                            : _buildFavoritesGrid(),
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
              AppTheme.accentOrange.withOpacity(0.05),
              AppTheme.primaryIndigo.withOpacity(0.05),
              AppTheme.accentCyan.withOpacity(0.03),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ),
      ),
      actions: [
        if (_favoriteBooks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => _isLoading = true);
                      _loadFavorites();
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.8),
                    Colors.white.withOpacity(0.6),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.accentOrange,
                              AppTheme.accentPink,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentOrange.withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  LinearGradient(
                                    colors: [
                                      AppTheme.accentOrange,
                                      AppTheme.accentPink,
                                    ],
                                  ).createShader(bounds),
                              child: Text(
                                "Favorilerim",
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                              ),
                            ),
                            if (_favoriteBooks.isNotEmpty)
                              Text(
                                "${_favoriteBooks.length} kitap",
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.accentOrange,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              "Favoriler yükleniyor...",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.neutralDark,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginRequiredState() {
    return SliverFillRemaining(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
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
                          AppTheme.accentCyan.withOpacity(0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.login_rounded,
                      size: 80,
                      color: AppTheme.primaryIndigo,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    "Favorileri görmek için giriş yap",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Beğendiğin kitapları favorilere ekleyebilirsin",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.neutralDark,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
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
                          AppTheme.accentOrange.withOpacity(0.1),
                          AppTheme.accentPink.withOpacity(0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.favorite_border_rounded,
                      size: 100,
                      color: AppTheme.accentOrange,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    "Henüz favori kitap yok",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Beğendiğin kitapları favorilere ekle!",
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
                        Navigator.pop(context);
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
        ),
      ),
    );
  }

  Widget _buildFavoritesGrid() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: PremiumBookCard(
                  book: _favoriteBooks[index],
                  index: index,
                  onUpdated: _loadFavorites,
                ),
              ),
            );
          },
          childCount: _favoriteBooks.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 0.65,
        ),
      ),
    );
  }
}