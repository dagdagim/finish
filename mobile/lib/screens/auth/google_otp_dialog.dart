import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/finish_button.dart';
import '../../core/widgets/finish_text_field.dart';
import '../../providers/auth_provider.dart';
import '../main_scaffold.dart';
import 'role_intent_screen.dart';

class GoogleOtpDialog extends StatefulWidget {
  final String? initialEmail;
  final String role; // 'customer' | 'tasker' | 'both'

  const GoogleOtpDialog({
    super.key,
    this.initialEmail,
    this.role = 'both',
  });

  static Future<void> show(
    BuildContext context, {
    String? initialEmail,
    String role = 'both',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GoogleOtpDialog(
        initialEmail: initialEmail,
        role: role,
      ),
    );
  }

  @override
  State<GoogleOtpDialog> createState() => _GoogleOtpDialogState();
}

class _GoogleOtpDialogState extends State<GoogleOtpDialog> {
  late final TextEditingController _emailController;
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _codeSent = false;
  bool _isLoading = false;
  String? _errorMessage;
  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _currentOtpCode => _otpControllers.map((c) => c.text).join();

  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = 'Please enter a valid Gmail / email address.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final res = await auth.sendGoogleOtp(email, purpose: 'Google Authentication');

    setState(() => _isLoading = false);

    if (res['success'] == true) {
      setState(() {
        _codeSent = true;
        _errorMessage = null;
      });
      _startResendTimer();
      // Auto-focus first digit
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _focusNodes[0].canRequestFocus) {
          _focusNodes[0].requestFocus();
        }
      });
    } else {
      setState(() {
        _errorMessage = res['message'] ?? 'Failed to deliver OTP to Gmail. Please try again.';
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    final code = _currentOtpCode;
    if (code.length != 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits of your verification code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim().toLowerCase();
    final auth = context.read<AuthProvider>();
    final res = await auth.verifyGoogleOtp(
      email: email,
      otp: code,
      role: widget.role,
    );

    setState(() => _isLoading = false);

    if (res['success'] == true && mounted) {
      Navigator.of(context).pop(); // Close bottom sheet

      final isNewUser = res['isNewUser'] == true;
      if (isNewUser) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RoleIntentScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScaffold()),
        );
      }
    } else {
      setState(() {
        _errorMessage = res['message'] ?? 'Invalid code. Please verify and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle pill
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header with Google Logo & Security Badge
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: Image.network(
                      'https://cdn1.iconfinder.com/data/icons/google-s-logo/150/Google_Icons-09-512.png',
                      width: 24,
                      height: 24,
                      errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata_rounded, size: 28, color: Color(0xFF4285F4)),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _codeSent ? 'Enter Gmail OTP' : 'Google Authentication',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _codeSent
                            ? 'Check ${_emailController.text.trim()}'
                            : 'Sign in or register with verified Gmail OTP',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Error banner if any
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTypography.bodySmall.copyWith(
                          color: const Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // STEP 1: Enter Gmail
            if (!_codeSent) ...[
              FinishTextField(
                controller: _emailController,
                label: 'Google / Gmail Address',
                hintText: 'e.g. name@gmail.com',
                prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.textMuted, size: 20),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleSendOtp(),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'A secure 6-digit verification code will be sent to your Gmail inbox. New users will be automatically registered.',
                        style: AppTypography.bodySmall.copyWith(
                          color: const Color(0xFF065F46),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FinishButton(
                text: 'Send Verification Code',
                isLoading: _isLoading,
                icon: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                onPressed: _isLoading ? null : _handleSendOtp,
              ),
            ]
            // STEP 2: Enter 6-Digit OTP
            else ...[
              Text(
                'Enter the 6-digit code sent to:',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _emailController.text.trim(),
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _timer?.cancel();
                      setState(() {
                        _codeSent = false;
                        _errorMessage = null;
                        for (final c in _otpControllers) {
                          c.clear();
                        }
                      });
                    },
                    child: Text(
                      'Change',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 6-box Pin Code Inputs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 44,
                    height: 52,
                    child: TextFormField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: AppColors.primary,
                      ),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty) {
                          if (index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          } else {
                            _focusNodes[index].unfocus();
                            if (_currentOtpCode.length == 6) {
                              _handleVerifyOtp();
                            }
                          }
                        } else {
                          if (index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Resend code countdown
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_secondsRemaining > 0)
                    Text(
                      'Resend code in ${_secondsRemaining}s',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _isLoading ? null : _handleSendOtp,
                      child: Text(
                        'Resend Code via Gmail',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Verify button
              FinishButton(
                text: 'Verify & Sign In',
                isLoading: _isLoading,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.white),
                onPressed: _isLoading ? null : _handleVerifyOtp,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
