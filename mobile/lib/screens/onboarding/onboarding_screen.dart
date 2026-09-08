import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/finish_button.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';

class OnboardingItem {
  final String title;
  final String description;
  final String imageUrl;
  final IconData placeholderIcon;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.placeholderIcon,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _pages = [
    OnboardingItem(
      title: 'Need something\ndone?',
      description: 'From errands to deliveries, find trusted people to help with your small jobs.',
      imageUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=800&auto=format&fit=crop&q=80',
      placeholderIcon: Icons.handshake_outlined,
    ),
    OnboardingItem(
      title: 'Find someone\nnearby.',
      description: 'Browse local taskers, compare ratings and choose the right person for your task.',
      imageUrl: 'https://images.unsplash.com/photo-1524850011238-e3d235c7d4c9?w=800&auto=format&fit=crop&q=80',
      placeholderIcon: Icons.location_on_outlined,
    ),
    OnboardingItem(
      title: 'Get it finished.',
      description: 'Track progress, stay updated and get your task done — simple and secure.',
      imageUrl: 'https://images.unsplash.com/photo-1580674684081-7617fbf3d745?w=800&auto=format&fit=crop&q=80',
      placeholderIcon: Icons.check_circle_outline,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onGetStarted() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
  }

  void _onSignIn() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Photographic & Visual Section
            Expanded(
              flex: 11,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final item = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            color: const Color(0xFFF0F4F2),
                            child: Image.network(
                              item.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.primaryLight,
                                  child: Center(
                                    child: Icon(item.placeholderIcon, size: 72, color: AppColors.primary),
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: const Color(0xFFF4F6F5),
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Subtle bottom vignette for depth
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 60,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.12),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Content Section (Warm Off-White feel)
            Expanded(
              flex: 9,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dynamic Headline
                    Text(
                      _pages[_currentPage].title,
                      style: AppTypography.displayLarge.copyWith(
                        fontSize: 26,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtitle
                    Text(
                      _pages[_currentPage].description,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textMuted,
                        height: 1.4,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pagination Dots
                    Row(
                      children: List.generate(_pages.length, (index) {
                        final isActive = _currentPage == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(right: 6),
                          width: isActive ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.primary : AppColors.border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    // Primary CTA
                    FinishButton(
                      text: 'Get Started',
                      onPressed: _onGetStarted,
                    ),
                    const SizedBox(height: 6),

                    // Secondary CTA
                    FinishButton(
                      text: 'Sign In',
                      variant: FinishButtonVariant.text,
                      height: 40,
                      onPressed: _onSignIn,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
