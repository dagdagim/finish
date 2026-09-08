import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/finish_button.dart';
import '../../data/models/task_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/api_service.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  bool _isLoading = false;
  Map<String, dynamic> _stats = {};
  List<UserModel> _users = [];
  List<TaskModel> _tasks = [];
  List<Map<String, dynamic>> _disputes = [];

  String _userRoleFilter = 'all';
  String _userStatusFilter = 'all';
  String _userSearchQuery = '';

  String _taskStatusFilter = 'all';
  String _taskSearchQuery = '';

  final TextEditingController _broadcastTitleController = TextEditingController();
  final TextEditingController _broadcastMsgController = TextEditingController();
  String _broadcastTargetRole = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadAllAdminData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _broadcastTitleController.dispose();
    _broadcastMsgController.dispose();
    super.dispose();
  }

  Future<void> _loadAllAdminData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _api.getAdminStats();
      final users = await _api.getAdminUsers(
        role: _userRoleFilter,
        status: _userStatusFilter,
        search: _userSearchQuery,
      );
      final tasks = await _api.getAdminTasks(
        status: _taskStatusFilter,
        search: _taskSearchQuery,
      );
      final disputes = await _api.getAdminDisputes();

      if (mounted) {
        setState(() {
          _stats = stats['metrics'] ?? {};
          _users = users;
          _tasks = tasks;
          _disputes = disputes;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- ACTIONS ---
  Future<void> _toggleUserVerification(UserModel user) async {
    final newStatus = !user.isIdentityVerified;
    final success = await _api.verifyAdminUser(user.id, verified: newStatus);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.fullName} identity ${newStatus ? 'VERIFIED' : 'UNVERIFIED'}'),
          backgroundColor: newStatus ? const Color(0xFF047857) : Colors.orange.shade800,
        ),
      );
      _loadAllAdminData();
    }
  }

  Future<void> _reviewTaskerVerification(UserModel user, String decision, {String? notes}) async {
    final isApproved = decision == 'APPROVED';
    final success = await _api.reviewAdminVerification(user.id, decision, notes: notes);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(isApproved ? Icons.verified : Icons.cancel, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isApproved
                      ? 'Verification APPROVED! Verified Tasker Badge ✓ granted to ${user.fullName}.'
                      : 'Verification REJECTED for ${user.fullName}.',
                ),
              ),
            ],
          ),
          backgroundColor: isApproved ? const Color(0xFF047857) : AppColors.error,
        ),
      );
      _loadAllAdminData();
    }
  }

  Widget _buildUniversalImage(String? src, {double? height, double? width, BoxFit fit = BoxFit.cover}) {
    if (src == null || src.isEmpty) {
      return Container(
        height: height,
        width: width,
        color: const Color(0xFFF3F4F6),
        child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted, size: 24),
      );
    }
    if (src.startsWith('data:image')) {
      try {
        final commaIndex = src.indexOf(',');
        final b64 = commaIndex != -1 ? src.substring(commaIndex + 1) : src;
        final bytes = base64Decode(b64);
        return Image.memory(bytes, height: height, width: width, fit: fit);
      } catch (_) {
        return Container(
          height: height,
          width: width,
          color: const Color(0xFFF3F4F6),
          child: const Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 24),
        );
      }
    }
    if (src.startsWith('http://') || src.startsWith('https://')) {
      return Image.network(
        src,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (_, __, ___) => Container(
          height: height,
          width: width,
          color: const Color(0xFFF3F4F6),
          child: const Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 24),
        ),
      );
    }
    if (!kIsWeb) {
      final file = File(src);
      if (file.existsSync()) {
        return Image.file(file, height: height, width: width, fit: fit);
      }
    }
    return Image.network(
      src,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        height: height,
        width: width,
        color: const Color(0xFFF3F4F6),
        child: const Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 24),
      ),
    );
  }

  void _openFullScreenImage(BuildContext context, String? src, String title) {
    if (src == null || src.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4.0,
                child: _buildUniversalImage(src, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 12,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDossierDocCard(
    BuildContext context, {
    required String title,
    required String? url,
    required IconData icon,
    required Color color,
  }) {
    final hasUrl = url != null && url.isNotEmpty;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (hasUrl) {
            _openFullScreenImage(context, url, title);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    _buildUniversalImage(url, height: 75, width: double.infinity),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 12, color: color),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryAnswersSection(String category, Map<dynamic, dynamic> answers) {
    if (answers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text('No extra category answers submitted.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
      );
    }

    final catLower = category.toLowerCase();

    if (catLower.contains('delivery')) {
      final vehicle = answers['vehicleType']?.toString() ?? 'Motorbike';
      final license = answers['licenseNumber']?.toString() ?? 'N/A';
      final licensePhoto = answers['driverLicensePhotoUrl']?.toString() ?? '';
      final hasBag = answers['hasInsulatedBag'] == true;
      final areas = (answers['preferredAreas'] is List) ? List<String>.from(answers['preferredAreas']) : <String>[];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDossierRow('Vehicle Type', vehicle),
          const Divider(height: 12),
          _buildDossierRow('Driver\'s License / Plate', license),
          if (licensePhoto.isNotEmpty) ...[
            const Divider(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Driver\'s License Document:', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                InkWell(
                  onTap: () => _openFullScreenImage(context, licensePhoto, 'Driver\'s License Document Proof'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF047857).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF047857).withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.attachment_rounded, size: 14, color: Color(0xFF047857)),
                        SizedBox(width: 4),
                        Text('Inspect License ↗', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF047857))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 12),
          _buildDossierRow('Insulated Thermal Bag', hasBag ? 'Equipped & Ready ✓' : 'No'),
          if (areas.isNotEmpty) ...[
            const Divider(height: 12),
            const Text('Preferred Service Areas in Addis:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: areas.map((a) => Chip(
                label: Text(a, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF047857))),
                backgroundColor: const Color(0xFFECFDF5),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList(),
            ),
          ],
        ],
      );
    } else if (catLower.contains('clean')) {
      final types = (answers['cleaningTypes'] is List) ? List<String>.from(answers['cleaningTypes']) : <String>[];
      final equipment = (answers['equipmentOwned'] is List) ? List<String>.from(answers['equipmentOwned']) : <String>[];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (types.isNotEmpty) ...[
            const Text('Cleaning Specializations:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: types.map((t) => Chip(
                label: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8))),
                backgroundColor: const Color(0xFFEFF6FF),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList(),
            ),
            const Divider(height: 14),
          ],
          if (equipment.isNotEmpty) ...[
            const Text('Owned Equipment & Supplies:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: equipment.map((e) => Chip(
                label: Text(e, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF047857))),
                backgroundColor: const Color(0xFFECFDF5),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList(),
            ),
          ],
        ],
      );
    } else if (catLower.contains('assembly') || catLower.contains('handyman')) {
      final tools = (answers['toolsOwned'] is List) ? List<String>.from(answers['toolsOwned']) : <String>[];
      final exp = (answers['assemblyExperience'] is List) ? List<String>.from(answers['assemblyExperience']) : <String>[];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tools.isNotEmpty) ...[
            const Text('Hardware Toolkit Inventory:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: tools.map((t) => Chip(
                label: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFB45309))),
                backgroundColor: const Color(0xFFFEF3C7),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList(),
            ),
            const Divider(height: 14),
          ],
          if (exp.isNotEmpty) ...[
            const Text('Mounting & Assembly Skills:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: exp.map((e) => Chip(
                label: Text(e, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF047857))),
                backgroundColor: const Color(0xFFECFDF5),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList(),
            ),
          ],
        ],
      );
    } else if (catLower.contains('plumb') || catLower.contains('electr')) {
      final cert = answers['certificationLevel']?.toString() ?? 'TVET Level 2 Certificate';
      final details = answers['experienceDetails']?.toString() ?? 'General residential maintenance';
      final hasGear = answers['hasSafetyGear'] == true;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDossierRow('TVET Qualification', cert),
          const Divider(height: 12),
          _buildDossierRow('PPE & Safety Gear', hasGear ? 'Equipped with Safety Gear ✓' : 'No'),
          const Divider(height: 12),
          const Text('Trade Background & Experience:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(details, style: const TextStyle(fontSize: 12.5, color: AppColors.textDark, height: 1.3)),
        ],
      );
    } else if (catLower.contains('moving')) {
      final capacity = answers['maxLiftCapacity']?.toString() ?? '50+ kg';
      final crew = answers['crewSize']?.toString() ?? '2 Helpers';
      final hasDolly = answers['hasMovingDolly'] == true;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDossierRow('Max Lifting Capacity', capacity),
          const Divider(height: 12),
          _buildDossierRow('Crew Size Available', crew),
          const Divider(height: 12),
          _buildDossierRow('Moving Dolly & Straps', hasDolly ? 'Equipped & Ready ✓' : 'No'),
        ],
      );
    } else if (catLower.contains('tech')) {
      final skills = (answers['techSkills'] is List) ? List<String>.from(answers['techSkills']) : <String>[];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('IT & Technical Capabilities:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: skills.map((s) => Chip(
              label: Text(s, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6D28D9))),
              backgroundColor: const Color(0xFFF5F3FF),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )).toList(),
          ),
        ],
      );
    }

    return Column(
      children: answers.entries.map((entry) {
        final key = entry.key.toString();
        final val = entry.value;
        final formattedVal = (val is List) ? val.join(', ') : val.toString();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(key, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
              Flexible(
                child: Text(
                  formattedVal,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.textDark),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showVerificationReviewModal(UserModel user) {
    final vData = user.verificationData ?? {
      'workExperienceYears': 3,
      'experienceDescription': 'Specialist in rapid motorcycle delivery across Bole and Sarbet with high customer ratings.',
      'educationalLevel': 'Vocational / TVET Diploma',
      'institutionName': 'General Wingate TVET College',
      'nationalIdNumber': 'ETH-AA-998822',
      'nationalIdFrontUrl': 'https://images.unsplash.com/photo-1633332755192-727a05c4013d?w=400',
      'nationalIdBackUrl': 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=400',
      'faceScanPhotoUrl': user.avatarUrl.isNotEmpty ? user.avatarUrl : 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
      'emergencyContactName': 'Almaz Tesfaye (Sister)',
      'emergencyContactPhone': '+251 911 887 766',
      'primaryCategory': 'delivery',
      'categoryAnswers': {
        'vehicleType': 'Motorbike (TVS Apache 160)',
        'licenseNumber': 'AA-DRV-44810-ETH',
        'hasInsulatedBag': true,
        'preferredAreas': ['Bole', 'Sarbet', 'Kazanchis'],
      },
    };

    final categoryAnswers = (vData['categoryAnswers'] is Map) ? (vData['categoryAnswers'] as Map) : {};
    final primaryCategory = (vData['primaryCategory'] ?? 'Delivery').toString();
    final eduDocUrl = vData['educationalCertificateUrl']?.toString();
    final faceScanUrl = vData['faceScanPhotoUrl']?.toString() ?? user.avatarUrl;
    final frontIdUrl = vData['nationalIdFrontUrl']?.toString() ?? vData['nationalIdPhotoUrl']?.toString();
    final backIdUrl = vData['nationalIdBackUrl']?.toString();
    final driverLicenseUrl = vData['driverLicensePhotoUrl']?.toString() ?? (categoryAnswers['driverLicensePhotoUrl']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.90,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF047857).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_user_rounded, color: Color(0xFF047857), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tasker Verification Dossier',
                              style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            Text(
                              'Review National ID, biometric scan, and category questionnaire',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textMuted),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: _buildUniversalImage(
                                user.avatarUrl.isNotEmpty
                                    ? user.avatarUrl
                                    : (faceScanUrl.isNotEmpty ? faceScanUrl : null),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        user.fullName,
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (user.isIdentityVerified) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF10B981)),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text('${user.phone} · ${user.email}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: user.verificationStatus == 'APPROVED'
                                            ? const Color(0xFFECFDF5)
                                            : const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: user.verificationStatus == 'APPROVED'
                                              ? const Color(0xFFA7F3D0)
                                              : const Color(0xFFFCD34D),
                                        ),
                                      ),
                                      child: Text(
                                        user.verificationStatus == 'APPROVED' ? '✓ VERIFIED' : 'PENDING REVIEW',
                                        style: TextStyle(
                                          color: user.verificationStatus == 'APPROVED'
                                              ? const Color(0xFF047857)
                                              : const Color(0xFF92400E),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Primary: ${primaryCategory.toUpperCase()}',
                                        style: const TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 10.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('🪪 Biometric Verification & ID Proof Documents', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 4),
                    const Text('Tap any document to inspect in high-resolution full screen zoom', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildDossierDocCard(
                          context,
                          title: 'Face Scan',
                          url: faceScanUrl,
                          icon: Icons.face_retouching_natural_rounded,
                          color: const Color(0xFF047857),
                        ),
                        const SizedBox(width: 8),
                        _buildDossierDocCard(
                          context,
                          title: 'ID Front',
                          url: frontIdUrl,
                          icon: Icons.badge_rounded,
                          color: const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 8),
                        _buildDossierDocCard(
                          context,
                          title: 'ID Back',
                          url: backIdUrl,
                          icon: Icons.flip_to_back_rounded,
                          color: const Color(0xFF7C3AED),
                        ),
                        if (driverLicenseUrl.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _buildDossierDocCard(
                            context,
                            title: 'Driver Lic.',
                            url: driverLicenseUrl,
                            icon: Icons.drive_eta_rounded,
                            color: const Color(0xFF0D9488),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('National / Kebele ID Number:', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          Text(
                            vData['nationalIdNumber'] ?? 'ETH-AA-998822',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textDark, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('🎓 Education & Work Experience', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        children: [
                          _buildDossierRow('Educational Level', vData['educationalLevel'] ?? 'Vocational / TVET Diploma'),
                          const Divider(height: 14),
                          _buildDossierRow('Institution / College', vData['institutionName'] ?? 'General Wingate TVET College'),
                          if (eduDocUrl != null && eduDocUrl.isNotEmpty) ...[
                            const Divider(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Attached Diploma / Certificate:', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                                InkWell(
                                  onTap: () => _openFullScreenImage(context, eduDocUrl, 'Educational Certificate / Diploma Proof'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF047857).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF047857).withOpacity(0.3)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.attachment_rounded, size: 14, color: Color(0xFF047857)),
                                        SizedBox(width: 4),
                                        Text('View Document ↗', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF047857))),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const Divider(height: 14),
                          _buildDossierRow('Work Experience', '${vData['workExperienceYears'] ?? 2} Years'),
                          const Divider(height: 14),
                          _buildDossierRow('Emergency Contact', '${vData['emergencyContactName'] ?? 'Sister'} (${vData['emergencyContactPhone'] ?? '+251 911 887 766'})'),
                          const Divider(height: 14),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Service History Summary:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textMuted)),
                                const SizedBox(height: 4),
                                Text(
                                  vData['experienceDescription'] ?? 'No detailed description provided.',
                                  style: const TextStyle(fontSize: 12.5, color: AppColors.textDark, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('🛠️ Category Skills & Operational Answers', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: _buildCategoryAnswersSection(primaryCategory, categoryAnswers),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _reviewTaskerVerification(user, 'REJECTED', notes: 'Incomplete or unverified identity documents.');
                      },
                      child: const Text('✕ Reject Application', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF047857),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _reviewTaskerVerification(user, 'APPROVED');
                      },
                      icon: const Icon(Icons.verified_rounded, size: 18),
                      label: const Text('Approve & Grant Badge ✓', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDossierRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.textDark),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Future<void> _toggleUserBlock(UserModel user) async {
    final newBlocked = !user.isBlocked;
    final success = await _api.toggleAdminUserStatus(user.id, isBlocked: newBlocked);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account for ${user.fullName} ${newBlocked ? 'SUSPENDED' : 'ACTIVATED'}'),
          backgroundColor: newBlocked ? AppColors.error : const Color(0xFF047857),
        ),
      );
      _loadAllAdminData();
    }
  }

  Future<void> _performTaskAction(TaskModel task, String action) async {
    if (action == 'RATE_USERS') {
      _showAdminRatingModal(task);
      return;
    }

    final success = await _api.performAdminTaskAction(task.id, action);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Admin action "$action" executed on "${task.title}".'),
          backgroundColor: const Color(0xFF047857),
        ),
      );
      _loadAllAdminData();
    }
  }

  Future<void> _resolveDispute(Map<String, dynamic> dispute, String decision) async {
    final id = dispute['id'] ?? dispute['_id'] ?? '';
    final success = await _api.resolveAdminDispute(id, decision);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dispute resolved in favor of ${decision == 'FAVOR_TASKER' ? 'Tasker' : 'Customer'}'),
          backgroundColor: const Color(0xFF047857),
        ),
      );
      _loadAllAdminData();
    }
  }

  Future<void> _sendBroadcast() async {
    final title = _broadcastTitleController.text.trim();
    final message = _broadcastMsgController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both broadcast title and message.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await _api.broadcastAdminAnnouncement(
      title,
      message,
      targetRole: _broadcastTargetRole,
    );

    if (success && mounted) {
      _broadcastTitleController.clear();
      _broadcastMsgController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.campaign_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('Announcement broadcasted live to all users across Addis Ababa!')),
            ],
          ),
          backgroundColor: Color(0xFF047857),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF064E3B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF34D399), size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'FINISH Master Control',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  Text(
                    'Super Administrator',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(color: Colors.white70, fontSize: 10.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
            tooltip: 'Refresh Data',
            onPressed: _loadAllAdminData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
            tooltip: 'Logout Admin',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF047857)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildUsersTab(),
                _buildTasksTab(),
                _buildDisputesTab(),
                _buildBroadcastTab(),
              ],
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _tabController.index,
          onTap: (index) {
            setState(() {
              _tabController.animateTo(index);
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF047857),
          unselectedItemColor: const Color(0xFF9CA3AF),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10.5),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Overview',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline_rounded),
              activeIcon: Icon(Icons.people_alt_rounded),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment_rounded),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.gavel_outlined),
              activeIcon: Icon(Icons.gavel_rounded),
              label: 'Disputes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.campaign_outlined),
              activeIcon: Icon(Icons.campaign_rounded),
              label: 'Broadcast',
            ),
          ],
        ),
      ),
    );
  }

  // ================= 1. OVERVIEW TAB ================= //
  Widget _buildOverviewTab() {
    final currency = NumberFormat('#,###');
    final totalVol = _stats['totalVolume'] ?? 584500;
    final platformRev = _stats['platformRevenue'] ?? 58450;
    final escrowHeld = _stats['escrowHeld'] ?? 27300;

    return RefreshIndicator(
      onRefresh: _loadAllAdminData,
      color: const Color(0xFF047857),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Financial Volume Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF064E3B), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF064E3B).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'GROSS MARKETPLACE VOLUME',
                        style: TextStyle(
                          color: const Color(0xFF6EE7B7),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '● Live Ledger',
                          style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${currency.format(totalVol)} ETB',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Platform 10% Fees', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                            const SizedBox(height: 3),
                            Text(
                              '+${currency.format(platformRev)} ETB',
                              style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 30, color: Colors.white24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Escrow Funds Held', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                            const SizedBox(height: 3),
                            Text(
                              '${currency.format(escrowHeld)} ETB',
                              style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live Metrics 2x2 Grid
            Text('Marketplace Activity', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.30,
              children: [
                _buildKpiCard(
                  'Total Users',
                  '${_stats['totalUsers'] ?? 1240}',
                  '${_stats['activeTaskers'] ?? 380} active taskers',
                  Icons.people_alt_rounded,
                  const Color(0xFF3B82F6),
                  () => _tabController.animateTo(1),
                ),
                _buildKpiCard(
                  'Active Jobs',
                  '${_stats['activeJobs'] ?? 42}',
                  'In progress right now',
                  Icons.pending_actions_rounded,
                  const Color(0xFF10B981),
                  () => _tabController.animateTo(2),
                ),
                _buildKpiCard(
                  'Completed Tasks',
                  '${_stats['completedTasks'] ?? 3290}',
                  '${_stats['completionRate'] ?? 98}% success rate',
                  Icons.task_alt_rounded,
                  const Color(0xFF8B5CF6),
                  () => _tabController.animateTo(2),
                ),
                _buildKpiCard(
                  'Open Disputes',
                  '${_stats['disputedTasks'] ?? _disputes.length}',
                  'Requires arbitration',
                  Icons.gavel_rounded,
                  const Color(0xFFEF4444),
                  () => _tabController.animateTo(3),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Control Actions
            Text('Quick Operations', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionBtn(
                    'Verify Taskers',
                    Icons.verified_user_rounded,
                    const Color(0xFF047857),
                    () {
                      setState(() {
                        _userRoleFilter = 'tasker';
                        _userStatusFilter = 'pending';
                      });
                      _tabController.animateTo(1);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionBtn(
                    'Broadcast Alert',
                    Icons.campaign_rounded,
                    const Color(0xFFD97706),
                    () => _tabController.animateTo(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: AppTypography.labelMedium.copyWith(color: AppColors.textMuted, fontSize: 12)),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            Text(
              value,
              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.textDark),
            ),
            Text(
              subtitle,
              style: AppTypography.labelMedium.copyWith(color: color, fontSize: 11, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= 2. USERS MANAGEMENT TAB ================= //
  Widget _buildUsersTab() {
    return Column(
      children: [
        // Search & Filter Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search by name, phone, or email...',
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (val) {
                  _userSearchQuery = val;
                  _loadAllAdminData();
                },
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All Users', _userRoleFilter == 'all' && _userStatusFilter == 'all', () {
                      setState(() {
                        _userRoleFilter = 'all';
                        _userStatusFilter = 'all';
                      });
                      _loadAllAdminData();
                    }),
                    _buildFilterChip('Taskers', _userRoleFilter == 'tasker', () {
                      setState(() {
                        _userRoleFilter = 'tasker';
                        _userStatusFilter = 'all';
                      });
                      _loadAllAdminData();
                    }),
                    _buildFilterChip('Customers', _userRoleFilter == 'customer', () {
                      setState(() {
                        _userRoleFilter = 'customer';
                        _userStatusFilter = 'all';
                      });
                      _loadAllAdminData();
                    }),
                    _buildFilterChip('Pending Verification', _userStatusFilter == 'pending', () {
                      setState(() {
                        _userRoleFilter = 'all';
                        _userStatusFilter = 'pending';
                      });
                      _loadAllAdminData();
                    }),
                    _buildFilterChip('Suspended', _userStatusFilter == 'blocked', () {
                      setState(() {
                        _userRoleFilter = 'all';
                        _userStatusFilter = 'blocked';
                      });
                      _loadAllAdminData();
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // User List with Pull-to-Refresh
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFF047857),
            onRefresh: _loadAllAdminData,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              itemCount: _users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final user = _users[index];
                return _buildUserCard(user);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: const Color(0xFF064E3B),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textDark,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        backgroundColor: const Color(0xFFF3F4F6),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: user.isBlocked ? AppColors.error.withOpacity(0.4) : const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE5E7EB),
                backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
                child: user.avatarUrl.isEmpty
                    ? Text(
                        user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.fullName,
                            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.isIdentityVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF10B981)),
                        ],
                        if (user.isBlocked) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'SUSPENDED',
                              style: TextStyle(color: AppColors.error, fontSize: 9.5, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${user.phone} · ${user.email}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: user.role == 'tasker'
                                ? const Color(0xFF10B981).withOpacity(0.12)
                                : user.role == 'admin'
                                    ? const Color(0xFF8B5CF6).withOpacity(0.12)
                                    : const Color(0xFF3B82F6).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user.role.toUpperCase(),
                            style: TextStyle(
                              color: user.role == 'tasker'
                                  ? const Color(0xFF047857)
                                  : user.role == 'admin'
                                      ? const Color(0xFF6D28D9)
                                      : const Color(0xFF1D4ED8),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (user.role != 'admin')
                          Text(
                            user.isNewTasker ? '★ New Tasker (0 jobs)' : '★ ${user.rating.toStringAsFixed(1)} (${user.completedTasksCount} jobs)',
                            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 11.5),
                          ),
                        if (user.verificationStatus == 'PENDING')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFCD34D)),
                            ),
                            child: const Text(
                              'PENDING REVIEW',
                              style: TextStyle(color: Color(0xFF92400E), fontSize: 9.5, fontWeight: FontWeight.w800),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 10),

          // Control Actions Row (Scrollable to prevent overflow)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Review Application Dossier Button (for taskers / pending)
                if (user.role == 'tasker' || user.verificationData != null || user.verificationStatus == 'PENDING') ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.assignment_ind_rounded, size: 14),
                    label: const Text(
                      'Review Dossier',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF047857),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      elevation: 0,
                    ),
                    onPressed: () => _showVerificationReviewModal(user),
                  ),
                  const SizedBox(width: 8),
                ],

                // Verify identity toggle
                OutlinedButton.icon(
                  icon: Icon(
                    user.isIdentityVerified ? Icons.cancel_outlined : Icons.verified_user_rounded,
                    size: 14,
                    color: user.isIdentityVerified ? Colors.orange.shade800 : const Color(0xFF047857),
                  ),
                  label: Text(
                    user.isIdentityVerified ? 'Revoke ID' : 'Quick Verify',
                    style: TextStyle(
                      color: user.isIdentityVerified ? Colors.orange.shade800 : const Color(0xFF047857),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: user.isIdentityVerified ? Colors.orange.shade300 : const Color(0xFF047857).withOpacity(0.5),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  onPressed: () => _toggleUserVerification(user),
                ),
                const SizedBox(width: 8),

                // Block / Unblock toggle
                OutlinedButton.icon(
                  icon: Icon(
                    user.isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                    size: 14,
                    color: user.isBlocked ? const Color(0xFF047857) : AppColors.error,
                  ),
                  label: Text(
                    user.isBlocked ? 'Activate' : 'Suspend',
                    style: TextStyle(
                      color: user.isBlocked ? const Color(0xFF047857) : AppColors.error,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: user.isBlocked ? const Color(0xFF047857).withOpacity(0.5) : AppColors.error.withOpacity(0.4),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  onPressed: () => _toggleUserBlock(user),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= 3. TASKS MANAGEMENT TAB ================= //
  Widget _buildTasksTab() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search tasks by title, customer, or note...',
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (val) {
                  _taskSearchQuery = val;
                  _loadAllAdminData();
                },
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All Statuses', _taskStatusFilter == 'all', () {
                      setState(() => _taskStatusFilter = 'all');
                      _loadAllAdminData();
                    }),
                    _buildFilterChip('Open', _taskStatusFilter == 'OPEN', () {
                      setState(() => _taskStatusFilter = 'OPEN');
                      _loadAllAdminData();
                    }),
                    _buildFilterChip('In Progress', _taskStatusFilter == 'IN_PROGRESS', () {
                      setState(() => _taskStatusFilter = 'IN_PROGRESS');
                      _loadAllAdminData();
                    }),
                    _buildFilterChip('Submitted', _taskStatusFilter == 'SUBMITTED', () {
                      setState(() => _taskStatusFilter = 'SUBMITTED');
                      _loadAllAdminData();
                    }),
                    _buildFilterChip('Paid', _taskStatusFilter == 'PAID', () {
                      setState(() => _taskStatusFilter = 'PAID');
                      _loadAllAdminData();
                    }),
                    _buildFilterChip('Cancelled', _taskStatusFilter == 'CANCELLED', () {
                      setState(() => _taskStatusFilter = 'CANCELLED');
                      _loadAllAdminData();
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final task = _tasks[index];
              return _buildTaskCard(task);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    Color statusColor = const Color(0xFF3B82F6);
    if (task.status == 'IN_PROGRESS') statusColor = const Color(0xFF10B981);
    if (task.status == 'SUBMITTED') statusColor = const Color(0xFFD97706);
    if (task.status == 'PAID') statusColor = const Color(0xFF047857);
    if (task.status == 'CANCELLED') statusColor = AppColors.error;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task.status,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 10.5),
                ),
              ),
              Text(
                '${task.pricing.budget.toInt()} ETB',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(task.title, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            '📍 ${task.pickupLocation.address}',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 8),

          // Tasker & Customer Participants Details Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customer', style: AppTypography.labelMedium.copyWith(color: AppColors.textMuted, fontSize: 10.5)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            task.customerName,
                            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.textDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 28, color: const Color(0xFFE5E7EB)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Assigned Tasker', style: AppTypography.labelMedium.copyWith(color: AppColors.textMuted, fontSize: 10.5)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.delivery_dining_rounded, size: 14, color: Color(0xFF047857)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            task.assignedTaskerName ?? 'Not Assigned',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: task.assignedTaskerName != null ? const Color(0xFF047857) : AppColors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Admin Rating Banner / Button (Prominent when task is finished or active)
          if (task.adminRatings != null) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _showAdminRatingModal(task),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFBBF24)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 16, color: Color(0xFFD97706)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Admin Rated · Tasker: ${task.adminRatings!.taskerRating}★ | Customer: ${task.adminRatings!.customerRating}★',
                        style: const TextStyle(color: Color(0xFF92400E), fontSize: 11, fontWeight: FontWeight.w800),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.edit_outlined, size: 13, color: Color(0xFF92400E)),
                  ],
                ),
              ),
            ),
          ] else if (task.status == 'PAID' || task.status == 'COMPLETED' || task.status == 'SUBMITTED') ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _showAdminRatingModal(task),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD97706).withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rounded, size: 15, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Rate Both Tasker & Customer (Admin Review)',
                      style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 8),

          // Admin Override Controls & Rating Trigger
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => _showAdminRatingModal(task),
                icon: const Icon(Icons.star_border_rounded, size: 16, color: Color(0xFFD97706)),
                label: Text(
                  task.adminRatings != null ? 'Edit Ratings' : 'Rate Users',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textMuted),
                onSelected: (action) => _performTaskAction(task, action),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'RATE_USERS',
                    child: Row(
                      children: [
                        Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 18),
                        SizedBox(width: 8),
                        Text('Rate Tasker & Customer'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'FORCE_APPROVE',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Color(0xFF047857), size: 18),
                        SizedBox(width: 8),
                        Text('Force Approve & Release Payout'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'FORCE_CANCEL_REFUND',
                    child: Row(
                      children: [
                        Icon(Icons.cancel_outlined, color: AppColors.error, size: 18),
                        SizedBox(width: 8),
                        Text('Force Cancel & Refund Customer'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'FORCE_START',
                    child: Row(
                      children: [
                        Icon(Icons.play_circle_outline, color: Color(0xFF3B82F6), size: 18),
                        SizedBox(width: 8),
                        Text('Force Start Live Job'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAdminRatingModal(TaskModel task) {
    int taskerRating = task.adminRatings?.taskerRating ?? 5;
    int customerRating = task.adminRatings?.customerRating ?? 5;
    final taskerNotesCtrl = TextEditingController(text: task.adminRatings?.taskerReview ?? '');
    final customerNotesCtrl = TextEditingController(text: task.adminRatings?.customerReview ?? '');

    final taskerName = task.assignedTaskerName ?? 'Assigned Tasker';
    final customerName = task.customerName.isNotEmpty ? task.customerName : 'Customer';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.stars_rounded, color: Color(0xFFD97706), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin Dual-Reputation Appraisal',
                                style: AppTypography.titleSmall.copyWith(fontSize: 16, fontWeight: FontWeight.w900),
                              ),
                              Text(
                                'Task: "${task.title}" (${task.pricing.budget} ETB)',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    const SizedBox(height: 16),

                    // 1. TASKER RATING SECTION
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF86EFAC).withOpacity(0.6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.delivery_dining_rounded, size: 18, color: Color(0xFF047857)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Tasker: $taskerName',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF064E3B)),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF047857),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$taskerRating.0 ★',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // 5 Stars Selector
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (idx) {
                              final starVal = idx + 1;
                              return IconButton(
                                icon: Icon(
                                  starVal <= taskerRating ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: const Color(0xFFF59E0B),
                                  size: 32,
                                ),
                                onPressed: () {
                                  setModalState(() => taskerRating = starVal);
                                },
                              );
                            }),
                          ),

                          // Quick Compliment Chips
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _buildQuickTagChip('⚡ Fast Delivery', taskerNotesCtrl, setModalState),
                              _buildQuickTagChip('🎯 High Quality', taskerNotesCtrl, setModalState),
                              _buildQuickTagChip('📍 Accurate GPS', taskerNotesCtrl, setModalState),
                              _buildQuickTagChip('🤝 Polite & Pro', taskerNotesCtrl, setModalState),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Tasker Notes Input
                          TextField(
                            controller: taskerNotesCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'Performance notes (e.g. Completed on time with clear proof)',
                              hintStyle: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.all(10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 2. CUSTOMER RATING SECTION
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF93C5FD).withOpacity(0.6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF1D4ED8)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Customer: $customerName',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E3A8A)),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1D4ED8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$customerRating.0 ★',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // 5 Stars Selector
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (idx) {
                              final starVal = idx + 1;
                              return IconButton(
                                icon: Icon(
                                  starVal <= customerRating ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: const Color(0xFFF59E0B),
                                  size: 32,
                                ),
                                onPressed: () {
                                  setModalState(() => customerRating = starVal);
                                },
                              );
                            }),
                          ),

                          // Quick Compliment Chips
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _buildQuickTagChip('💰 Quick Payout', customerNotesCtrl, setModalState),
                              _buildQuickTagChip('📝 Clear Instructions', customerNotesCtrl, setModalState),
                              _buildQuickTagChip('📱 Responsive', customerNotesCtrl, setModalState),
                              _buildQuickTagChip('🌟 Great Client', customerNotesCtrl, setModalState),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Customer Notes Input
                          TextField(
                            controller: customerNotesCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'Customer review notes (e.g. Prompt escrow release and responsive communication)',
                              hintStyle: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.all(10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    FinishButton(
                      text: 'Submit Admin Ratings (Tasker: $taskerRating★ · Customer: $customerRating★)',
                      height: 50,
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        final success = await _api.rateAdminTask(
                          task.id,
                          taskerRating: taskerRating,
                          taskerReview: taskerNotesCtrl.text.isNotEmpty ? taskerNotesCtrl.text : 'Admin rated performance: $taskerRating/5 stars.',
                          customerRating: customerRating,
                          customerReview: customerNotesCtrl.text.isNotEmpty ? customerNotesCtrl.text : 'Admin rated cooperation: $customerRating/5 stars.',
                        );

                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '⭐ Admin ratings saved! Tasker ($taskerRating★) & Customer ($customerRating★) reputations updated.',
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFF047857),
                              duration: const Duration(seconds: 4),
                            ),
                          );
                          _loadAllAdminData();
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickTagChip(String label, TextEditingController controller, StateSetter setModalState) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onPressed: () {
        setModalState(() {
          if (controller.text.isEmpty) {
            controller.text = label;
          } else if (!controller.text.contains(label)) {
            controller.text = '${controller.text}, $label';
          }
        });
      },
    );
  }

  // ================= 4. DISPUTES RESOLUTION TAB ================= //
  Widget _buildDisputesTab() {
    if (_disputes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.gavel_rounded, size: 60, color: Color(0xFF10B981)),
            const SizedBox(height: 16),
            Text('No Active Disputes', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('All customer and tasker jobs are running smoothly.', style: AppTypography.bodyMedium),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _disputes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final disp = _disputes[index];
        final isResolved = disp['status'] == 'RESOLVED';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isResolved ? const Color(0xFFE5E7EB) : AppColors.error.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isResolved ? const Color(0xFF047857).withOpacity(0.12) : AppColors.error.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isResolved ? 'RESOLVED' : 'ACTIVE DISPUTE',
                      style: TextStyle(
                        color: isResolved ? const Color(0xFF047857) : AppColors.error,
                        fontWeight: FontWeight.w800,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                  Text(
                    '${disp['amount'] ?? 1200} ETB in Escrow',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.primaryDark),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                disp['taskTitle'] ?? 'Task Dispute',
                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reason: ${disp['reason'] ?? 'Service Disagreement'}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      disp['description'] ?? 'Customer and tasker could not agree on job completion quality.',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Customer: ${disp['customerName'] ?? 'Dawit A.'}',
                      style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Tasker: ${disp['taskerName'] ?? 'Yared B.'}',
                      style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (!isResolved) ...[
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF047857),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => _resolveDispute(disp, 'FAVOR_TASKER'),
                        child: const Text('Release to Tasker 💰', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => _resolveDispute(disp, 'FAVOR_CUSTOMER'),
                        child: const Text('Refund Customer 🔄', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ================= 5. LIVE BROADCAST TAB ================= //
  Widget _buildBroadcastTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF064E3B), Color(0xFF047857)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.campaign_rounded, color: Colors.white, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Live Citywide Broadcast',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Send real-time alerts to active customer & tasker apps across Addis Ababa.',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text('Target Audience', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTargetRoleRadio('all', 'All Users 👥'),
              const SizedBox(width: 8),
              _buildTargetRoleRadio('tasker', 'Taskers Only 🛵'),
              const SizedBox(width: 8),
              _buildTargetRoleRadio('customer', 'Customers Only 👤'),
            ],
          ),
          const SizedBox(height: 16),

          Text('Announcement Title', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          TextField(
            controller: _broadcastTitleController,
            decoration: InputDecoration(
              hintText: 'e.g. Rainy Weather Surge Pricing Active',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),

          Text('Announcement Message', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          TextField(
            controller: _broadcastMsgController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'e.g. Expect higher demand and earn 20% bonus in Bole & Kazanchis for the next 2 hours!',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),

          FinishButton(
            text: '📢 Broadcast Announcement Now',
            onPressed: _sendBroadcast,
          ),
        ],
      ),
    );
  }

  Widget _buildTargetRoleRadio(String value, String label) {
    final isSelected = _broadcastTargetRole == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _broadcastTargetRole = value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF064E3B) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? const Color(0xFF064E3B) : const Color(0xFFE5E7EB)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textDark,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
