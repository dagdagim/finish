import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/finish_button.dart';
import '../../core/widgets/finish_text_field.dart';
import '../../providers/auth_provider.dart';
import 'role_intent_screen.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  String _selectedRole = 'both'; // 'customer', 'tasker', 'both'
  String? _inlineError;
  bool _agreedToTerms = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Live password strength calculation
  int _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;
    int strength = 0;
    if (password.length >= 6) strength++;
    if (password.length >= 8) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#\$&*~A-Z]').hasMatch(password)) strength++;
    return strength;
  }

  Future<void> _handleSignUp() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    String rawPhone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _inlineError = null;
    });

    if (firstName.isEmpty || lastName.isEmpty || rawPhone.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        _inlineError = 'Please fill in all required fields to continue.';
      });
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _inlineError = 'Please enter a valid email address (e.g. name@example.com).';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _inlineError = 'Password must be at least 6 characters long.';
      });
      return;
    }

    if (!_agreedToTerms) {
      setState(() {
        _inlineError = 'Please agree to the Terms of Service & Privacy Policy.';
      });
      return;
    }

    // Format phone with +251 if not present
    String formattedPhone = rawPhone;
    if (!formattedPhone.startsWith('+')) {
      if (formattedPhone.startsWith('0')) {
        formattedPhone = '+251${formattedPhone.substring(1)}';
      } else if (formattedPhone.startsWith('251')) {
        formattedPhone = '+$formattedPhone';
      } else {
        formattedPhone = '+251$formattedPhone';
      }
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signup(
      firstName: firstName,
      lastName: lastName,
      phone: formattedPhone,
      email: email,
      password: password,
      role: _selectedRole,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RoleIntentScreen()),
      );
    } else if (mounted) {
      setState(() {
        _inlineError = authProvider.errorMessage ?? 'Registration failed. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  authProvider.errorMessage ?? 'Registration failed. Please try again.',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final passwordStrength = _calculatePasswordStrength(_passwordController.text);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Addis Ababa',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Branded Hero Header
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF087F5B), Color(0xFF065F44)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF087F5B).withOpacity(0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person_add_alt_1_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FINISH',
                          style: AppTypography.displayLarge.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'Small jobs. Real people. Done.',
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Headline
                Text(
                  'Create Account',
                  style: AppTypography.displayLarge.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Join Addis Ababa’s trusted micro-task marketplace.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 22),

                // Interactive Mode Switcher (Log In <-> Sign Up Tab Pill)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(11),
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) => const LoginScreen(),
                                transitionDuration: Duration.zero,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: Text(
                                'Log In',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(11),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Sign Up',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Inline Error Banner
                if (_inlineError != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _inlineError!,
                            style: AppTypography.bodyMedium.copyWith(
                              color: const Color(0xFFB91C1C),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _inlineError = null),
                          child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFB91C1C)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // Role Intent Pills (How would you like to use Finish?)
                Text(
                  'I want to use FINISH to:',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildRoleChip(
                      label: 'Hire Help',
                      icon: Icons.add_task_rounded,
                      role: 'customer',
                      selected: _selectedRole == 'customer',
                    ),
                    const SizedBox(width: 8),
                    _buildRoleChip(
                      label: 'Do Tasks',
                      icon: Icons.handyman_rounded,
                      role: 'tasker',
                      selected: _selectedRole == 'tasker',
                    ),
                    const SizedBox(width: 8),
                    _buildRoleChip(
                      label: 'Both',
                      icon: Icons.swap_horiz_rounded,
                      role: 'both',
                      selected: _selectedRole == 'both',
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Name Row
                Row(
                  children: [
                    Expanded(
                      child: FinishTextField(
                        controller: _firstNameController,
                        label: 'First Name',
                        hintText: 'Sarah',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FinishTextField(
                        controller: _lastNameController,
                        label: 'Last Name',
                        hintText: 'Mamo',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Phone Number with Clean +251 Country Prefix
                FinishTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hintText: '911 223 344',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '+251',
                          style: AppTypography.labelLarge.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 1,
                          height: 18,
                          color: const Color(0xFFE5E7EB),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Email Address
                FinishTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hintText: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                ),
                const SizedBox(height: 16),

                // Password
                FinishTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hintText: 'At least 6 characters',
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  onChanged: (_) => setState(() {}),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),

                // Password Strength Indicator
                if (_passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(4, (index) {
                      final isActive = index < passwordStrength;
                      Color barColor = const Color(0xFFE5E7EB);
                      if (isActive) {
                        if (passwordStrength == 1) {
                          barColor = AppColors.error;
                        } else if (passwordStrength <= 2) {
                          barColor = const Color(0xFFF59E0B);
                        } else {
                          barColor = AppColors.primary;
                        }
                      }
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        passwordStrength <= 1
                            ? 'Weak password'
                            : passwordStrength <= 2
                                ? 'Medium password'
                                : 'Strong password',
                        style: AppTypography.labelMedium.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: passwordStrength <= 1
                              ? AppColors.error
                              : passwordStrength <= 2
                                  ? const Color(0xFFD97706)
                                  : AppColors.primary,
                        ),
                      ),
                      Text(
                        'Min 6 chars',
                        style: AppTypography.labelMedium.copyWith(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 18),

                // Terms of Service Agreement Checkbox
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _agreedToTerms,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          onChanged: (val) => setState(() => _agreedToTerms = val ?? true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'I agree to the ',
                            style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                            children: [
                              TextSpan(
                                text: 'Terms of Service',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Sign Up CTA Button
                FinishButton(
                  text: 'Create My Account',
                  isLoading: authProvider.isLoading,
                  onPressed: _handleSignUp,
                ),
                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0),
                      child: Text(
                        'Or continue with',
                        style: AppTypography.labelMedium.copyWith(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                  ],
                ),
                const SizedBox(height: 18),

                // Social OAuth Buttons
                Row(
                  children: [
                    Expanded(
                      child: FinishButton(
                        height: 48,
                        text: 'Google',
                        variant: FinishButtonVariant.outline,
                        icon: const Icon(Icons.g_mobiledata_rounded, size: 24, color: AppColors.textDark),
                        onPressed: () async {
                          final auth = context.read<AuthProvider>();
                          final success = await auth.login('sarah@finish.et', 'Finish2026!');
                          if (success && mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const RoleIntentScreen()),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FinishButton(
                        height: 48,
                        text: 'Apple',
                        variant: FinishButtonVariant.outline,
                        icon: const Icon(Icons.apple_rounded, size: 20, color: AppColors.textDark),
                        onPressed: () async {
                          final auth = context.read<AuthProvider>();
                          final success = await auth.login('sarah@finish.et', 'Finish2026!');
                          if (success && mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const RoleIntentScreen()),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Footer: Log In Switch
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTypography.bodyMedium.copyWith(fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => const LoginScreen(),
                              transitionsBuilder: (_, animation, __, child) {
                                return FadeTransition(opacity: animation, child: child);
                              },
                              transitionDuration: const Duration(milliseconds: 200),
                            ),
                          );
                        },
                        child: Text(
                          'Log In',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip({
    required String label,
    required IconData icon,
    required String role,
    required bool selected,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFE5E7EB),
              width: selected ? 1.6 : 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? AppColors.primaryDark : AppColors.textMuted,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.labelMedium.copyWith(
                  color: selected ? AppColors.primaryDark : AppColors.textDark,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
