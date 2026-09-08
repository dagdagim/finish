import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/finish_button.dart';
import '../../core/widgets/finish_text_field.dart';
import '../../data/models/wallet_model.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/auth_provider.dart';

class TaskerWalletScreen extends StatefulWidget {
  const TaskerWalletScreen({super.key});

  @override
  State<TaskerWalletScreen> createState() => _TaskerWalletScreenState();
}

class _TaskerWalletScreenState extends State<TaskerWalletScreen> {
  bool _showCardDetails = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWallet();
    });
  }

  // Multi-Bank Withdrawal Modal
  void _showWithdrawalModal(int availableBalance, bool isFrozen) {
    if (isFrozen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your Finish Visa Card is currently frozen. Please unfreeze it first to withdraw.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final taskerName = (user?.fullName.isNotEmpty == true) ? user!.fullName : 'Daniel Kebede';
    final taskerPhone = (user?.phone.isNotEmpty == true) ? user!.phone : '0912345678';

    final amountController = TextEditingController(text: '500');
    final accountController = TextEditingController(text: taskerPhone);
    final accountNameController = TextEditingController(text: taskerName);
    String selectedMethod = 'telebirr';
    String selectedBankName = 'Telebirr SuperApp';

    final Map<String, String> cachedBankAccounts = {
      'cbe_bank': '',
      'awash': '',
      'dashen': '',
      'abyssinia': '',
    };

    final methods = [
      {'id': 'telebirr', 'name': 'Telebirr', 'logo': '📱', 'color': const Color(0xFF0072CE)},
      {'id': 'cbe', 'name': 'CBE Birr', 'logo': '🏦', 'color': const Color(0xFF781E2E)},
      {'id': 'cbe_bank', 'name': 'CBE Bank Account', 'logo': '💳', 'color': const Color(0xFF6B21A8)},
      {'id': 'awash', 'name': 'Awash Bank', 'logo': '🏛️', 'color': const Color(0xFF047857)},
      {'id': 'dashen', 'name': 'Dashen Bank', 'logo': '🏧', 'color': const Color(0xFFB45309)},
      {'id': 'abyssinia', 'name': 'Bank of Abyssinia', 'logo': '✨', 'color': const Color(0xFF1E3A8A)},
    ];

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
            final isMobileMoney = selectedMethod == 'telebirr' || selectedMethod == 'cbe';

            String accountLabel;
            String accountHint;
            if (selectedMethod == 'telebirr') {
              accountLabel = 'Telebirr Phone Number';
              accountHint = 'e.g. 0912345678';
            } else if (selectedMethod == 'cbe') {
              accountLabel = 'CBE Birr Phone Number';
              accountHint = 'e.g. 0912345678';
            } else if (selectedMethod == 'cbe_bank') {
              accountLabel = 'CBE Bank Account Number';
              accountHint = 'Enter 13-digit CBE account number';
            } else if (selectedMethod == 'awash') {
              accountLabel = 'Awash Bank Account Number';
              accountHint = 'Enter your Awash Bank account number';
            } else if (selectedMethod == 'dashen') {
              accountLabel = 'Dashen Bank Account Number';
              accountHint = 'Enter your Dashen Bank account number';
            } else {
              accountLabel = 'Bank of Abyssinia Account Number';
              accountHint = 'Enter your Bank of Abyssinia account number';
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
                left: 20,
                right: 20,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_upward_rounded, color: Color(0xFF047857), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Instant Withdrawal', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800, fontSize: 17)),
                            Text('Available: $availableBalance ETB · 0% Payout Fee', style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Destination Method Selector
                    const Text('Select Payout Destination', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: methods.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, index) {
                          final m = methods[index];
                          final isSelected = selectedMethod == m['id'];
                          return InkWell(
                            onTap: () {
                              setModalState(() {
                                // Cache existing bank account input if was a bank
                                if (!isMobileMoney) {
                                  cachedBankAccounts[selectedMethod] = accountController.text.trim();
                                }

                                selectedMethod = m['id'] as String;
                                selectedBankName = m['name'] as String;

                                if (selectedMethod == 'telebirr' || selectedMethod == 'cbe') {
                                  accountController.text = taskerPhone;
                                } else {
                                  accountController.text = cachedBankAccounts[selectedMethod] ?? '';
                                }
                                accountNameController.text = taskerName;
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF064E3B) : const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF064E3B) : const Color(0xFFE5E7EB),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(m['logo'] as String, style: const TextStyle(fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Text(
                                    m['name'] as String,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.textDark,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick Amount Chips
                    const Text('Amount to withdraw', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    Row(
                      children: [200, 500, 1000, availableBalance].map((amt) {
                        final isSelected = amountController.text == amt.toString();
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.5),
                            child: InkWell(
                              onTap: () {
                                setModalState(() {
                                  amountController.text = amt.toString();
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFD1FAE5) : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isSelected ? const Color(0xFF10B981) : Colors.transparent),
                                ),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      amt == availableBalance ? 'All' : '$amt ETB',
                                      style: TextStyle(
                                        color: isSelected ? const Color(0xFF065F46) : AppColors.textDark,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),

                    FinishTextField(
                      controller: amountController,
                      label: 'Custom Amount',
                      hintText: '500',
                      keyboardType: TextInputType.number,
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Center(widthFactor: 1, child: Text('ETB', style: AppTypography.labelLarge)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    FinishTextField(
                      controller: accountController,
                      label: accountLabel,
                      hintText: accountHint,
                      keyboardType: isMobileMoney ? TextInputType.phone : TextInputType.number,
                      onChanged: (val) {
                        if (!isMobileMoney) {
                          cachedBankAccounts[selectedMethod] = val.trim();
                        }
                      },
                    ),
                    if (isMobileMoney)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, size: 12, color: Color(0xFF047857)),
                            const SizedBox(width: 4),
                            Text(
                              'Auto-filled with registered phone ($taskerPhone)',
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF047857), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),

                    FinishTextField(
                      controller: accountNameController,
                      label: 'Account Holder Name',
                      hintText: taskerName,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_outlined, size: 12, color: Color(0xFF2563EB)),
                          const SizedBox(width: 4),
                          Text(
                            'Verified Tasker Profile: $taskerName',
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    FinishButton(
                      text: 'Confirm & Transfer Now',
                      icon: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 18),
                      onPressed: () async {
                        final amount = int.tryParse(amountController.text) ?? 0;
                        final accountNum = accountController.text.trim();
                        if (amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid amount.')),
                          );
                          return;
                        }
                        if (amount > availableBalance) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Amount exceeds available card balance.')),
                          );
                          return;
                        }
                        if (accountNum.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Please enter your $accountLabel.')),
                          );
                          return;
                        }

                        Navigator.of(ctx).pop();
                        final success = await context.read<WalletProvider>().withdraw(
                          amount: amount,
                          method: selectedMethod,
                          accountNumber: accountNum,
                          accountName: accountNameController.text.trim(),
                          bankName: selectedBankName,
                        );

                        if (mounted && success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text('Successfully transferred $amount ETB to $selectedBankName ($accountNum)!'),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFF047857),
                            ),
                          );
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

  // Top-Up / Deposit Modal
  void _showDepositModal() {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final taskerPhone = (user?.phone.isNotEmpty == true) ? user!.phone : '0911223344';

    final amountController = TextEditingController(text: '1000');
    final phoneController = TextEditingController(text: taskerPhone);
    String selectedMethod = 'telebirr';

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
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
                left: 20,
                right: 20,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add_card_rounded, color: Color(0xFF2563EB), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Deposit / Add Funds', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800, fontSize: 17)),
                            const Text('Direct credit to your Finish Virtual Visa Card', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Payment Provider
                    const Text('Select Payment Method', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => selectedMethod = 'telebirr'),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selectedMethod == 'telebirr' ? const Color(0xFFEFF6FF) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedMethod == 'telebirr' ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
                                  width: selectedMethod == 'telebirr' ? 2 : 1,
                                ),
                              ),
                              child: const Center(
                                child: Text('📱 Telebirr', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E3A8A))),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => selectedMethod = 'cbe'),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selectedMethod == 'cbe' ? const Color(0xFFEFF6FF) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedMethod == 'cbe' ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
                                  width: selectedMethod == 'cbe' ? 2 : 1,
                                ),
                              ),
                              child: const Center(
                                child: Text('🏦 CBE Birr', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E3A8A))),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Quick Top-up Amount Chips
                    Row(
                      children: [200, 500, 1000, 2500].map((amt) {
                        final isSelected = amountController.text == amt.toString();
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.5),
                            child: InkWell(
                              onTap: () => setModalState(() => amountController.text = amt.toString()),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFDBEAFE) : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isSelected ? const Color(0xFF2563EB) : Colors.transparent),
                                ),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '+$amt ETB',
                                      style: TextStyle(
                                        color: isSelected ? const Color(0xFF1E40AF) : AppColors.textDark,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),

                    FinishTextField(
                      controller: amountController,
                      label: 'Deposit Amount',
                      hintText: '1000',
                      keyboardType: TextInputType.number,
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Center(widthFactor: 1, child: Text('ETB', style: AppTypography.labelLarge)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    FinishTextField(
                      controller: phoneController,
                      label: 'Payment Phone Number',
                      hintText: '0911223344',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),

                    FinishButton(
                      text: 'Confirm Deposit',
                      icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                      onPressed: () async {
                        final amount = int.tryParse(amountController.text) ?? 0;
                        if (amount <= 0) return;

                        Navigator.of(ctx).pop();
                        final success = await context.read<WalletProvider>().topUp(
                          amount: amount,
                          method: selectedMethod,
                          phoneNumber: phoneController.text.trim(),
                        );

                        if (mounted && success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Deposit of $amount ETB credited to your Finish Visa Card!'),
                              backgroundColor: const Color(0xFF047857),
                            ),
                          );
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

  // Detailed Digital Receipt Modal
  void _showReceiptModal(TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tx.isCredit ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  tx.icon,
                  size: 28,
                  color: tx.isCredit ? const Color(0xFF047857) : const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tx.typeLabel,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textDark),
              ),
              const SizedBox(height: 4),
              Text(
                tx.isCredit ? '+${tx.amount} ETB' : '${tx.amount} ETB',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: tx.isCredit ? const Color(0xFF047857) : const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFF3F4F6)),
              const SizedBox(height: 12),

              _buildReceiptRow('Status', '✓ ${tx.status}', isHighlight: true),
              _buildReceiptRow('Description', tx.description),
              if (tx.referenceId != null) _buildReceiptRow('Reference ID', tx.referenceId!),
              if (tx.bankName != null) _buildReceiptRow('Destination / Channel', tx.bankName!),
              _buildReceiptRow('Card Mask', 'Visa •••• ${tx.cardLast4}'),
              _buildReceiptRow('Timestamp', '${tx.createdAt.year}-${tx.createdAt.month.toString().padLeft(2, '0')}-${tx.createdAt.day.toString().padLeft(2, '0')} ${tx.createdAt.hour.toString().padLeft(2, '0')}:${tx.createdAt.minute.toString().padLeft(2, '0')}'),

              const SizedBox(height: 20),
              FinishButton(
                text: 'Done',
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
              color: isHighlight ? const Color(0xFF047857) : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final wallet = walletProvider.wallet;
    final card = wallet.card;
    final transactions = walletProvider.filteredTransactions;
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final userName = user?.fullName.toUpperCase() ?? card.cardholderName;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Finish Visa Card',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: card.isFrozen ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: card.isFrozen ? const Color(0xFFFECACA) : const Color(0xFF86EFAC)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  card.isFrozen ? Icons.lock_rounded : Icons.check_circle_rounded,
                  size: 11,
                  color: card.isFrozen ? const Color(0xFFDC2626) : const Color(0xFF15803D),
                ),
                const SizedBox(width: 3),
                Text(
                  card.isFrozen ? 'FROZEN' : 'ACTIVE',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: card.isFrozen ? const Color(0xFFDC2626) : const Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 19, color: AppColors.textDark),
            tooltip: 'Refresh Ledger',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            onPressed: () => walletProvider.fetchWallet(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => walletProvider.fetchWallet(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. STATE-OF-THE-ART VIRTUAL VISA CARD
                _buildVirtualVisaCard(wallet, card, userName),

                const SizedBox(height: 12),

                // 2. QUICK CARD SECURITY & DISPLAY CONTROLS
                _buildCardControls(card, walletProvider),

                const SizedBox(height: 18),

                // 3. ACTION BUTTONS (WITHDRAW & DEPOSIT)
                Row(
                  children: [
                    Expanded(
                      child: FinishButton(
                        text: 'Withdraw',
                        icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 18),
                        onPressed: () => _showWithdrawalModal(wallet.availableBalance, card.isFrozen),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FinishButton(
                        text: 'Add Funds',
                        variant: FinishButtonVariant.outline,
                        icon: const Icon(Icons.add_card_rounded, color: AppColors.primary, size: 18),
                        onPressed: _showDepositModal,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // 4. FINANCIAL STATS (ESCROW & TOTAL EARNED)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.lock_clock_rounded, color: Color(0xFFD97706), size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Pending Escrow', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                                  Text('${wallet.pendingBalance} ETB', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 32, color: const Color(0xFFE5E7EB)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.trending_up_rounded, color: Color(0xFF047857), size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Earned', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                                  Text('${wallet.totalEarned} ETB', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF047857))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 5. TRANSACTION LEDGER HEADER & FILTER CHIPS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Financial Ledger',
                      style: AppTypography.titleSmall.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${walletProvider.filteredTransactions.length} records',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Filter Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('ALL', 'All', walletProvider),
                      _buildFilterChip('EARNINGS', 'Earnings 💰', walletProvider),
                      _buildFilterChip('WITHDRAWALS', 'Withdrawals ↗️', walletProvider),
                      _buildFilterChip('DEPOSITS', 'Deposits ↙️', walletProvider),
                      _buildFilterChip('ESCROW', 'Escrow 🔒', walletProvider),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 6. TRANSACTION ITEMS
                if (transactions.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 36, color: Color(0xFF9CA3AF)),
                        SizedBox(height: 8),
                        Text('No transactions found in this category', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      return InkWell(
                        onTap: () => _showReceiptModal(tx),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: tx.isCredit ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  tx.icon,
                                  color: tx.isCredit ? const Color(0xFF047857) : const Color(0xFFDC2626),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.description,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          tx.typeLabel,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: tx.isCredit ? const Color(0xFF047857) : const Color(0xFF991B1B),
                                          ),
                                        ),
                                        if (tx.referenceId != null) ...[
                                          const Text(' · ', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10)),
                                          Text(tx.referenceId!, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    tx.isCredit ? '+${tx.amount} ETB' : '${tx.amount} ETB',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      color: tx.isCredit ? const Color(0xFF047857) : const Color(0xFFDC2626),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${tx.createdAt.month}/${tx.createdAt.day}',
                                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 3D Virtual Visa Card Widget
  Widget _buildVirtualVisaCard(WalletModel wallet, VirtualCardModel card, String userName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: card.isFrozen
            ? const LinearGradient(
                colors: [Color(0xFF334155), Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF064E3B), Color(0xFF0F172A), Color(0xFF065F46)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: card.isFrozen ? const Color(0xFF64748B) : const Color(0xFF34D399).withOpacity(0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: card.isFrozen
                ? Colors.black.withOpacity(0.2)
                : const Color(0xFF064E3B).withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Brand & Contactless Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFFBBF24)),
                        SizedBox(width: 4),
                        Text(
                          'FINISH',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('DEBIT', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                ],
              ),
              const Icon(Icons.contactless_rounded, color: Colors.white70, size: 22),
            ],
          ),
          const SizedBox(height: 14),

          // Center: EMV Chip & Available Balance
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Realistic Metallic EMV Chip
              Container(
                width: 38,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFDE68A), Color(0xFFD97706), Color(0xFFFBBF24)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0xFFB45309), width: 0.8),
                ),
                child: Center(
                  child: Container(
                    width: 22,
                    height: 16,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF78350F).withOpacity(0.6), width: 0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('AVAILABLE BALANCE', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${wallet.availableBalance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}.00 ETB',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Card Number (Masked or Revealed)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _showCardDetails ? card.formattedCardNumber : card.maskedCardNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: card.cardNumber.replaceAll(' ', '')));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Card number copied to clipboard!')),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.copy_rounded, color: Colors.white70, size: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bottom: Cardholder, Expiry, CVV & VISA logo
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Card Holder (Flexible with ellipsis)
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CARD HOLDER', style: TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                    const SizedBox(height: 2),
                    Text(
                      userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Expires
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('EXPIRES', style: TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                  const SizedBox(height: 2),
                  Text(
                    card.expiryDate,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(width: 8),

              // CVV
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CVV', style: TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                  const SizedBox(height: 2),
                  Text(
                    _showCardDetails ? card.cvv : '•••',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(width: 8),

              // VISA Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'VISA',
                  style: TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Quick Card Controls
  Widget _buildCardControls(VirtualCardModel card, WalletProvider walletProvider) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              setState(() {
                _showCardDetails = !_showCardDetails;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _showCardDetails ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 15,
                    color: AppColors.textDark,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _showCardDetails ? 'Hide Details' : 'Show Details',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: () async {
              await walletProvider.toggleFreezeCard();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(card.isFrozen ? 'Finish Visa Card unlocked and active.' : 'Finish Visa Card has been frozen.'),
                    backgroundColor: card.isFrozen ? const Color(0xFF047857) : const Color(0xFFDC2626),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: card.isFrozen ? const Color(0xFFFEE2E2) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: card.isFrozen ? const Color(0xFFFECACA) : const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    card.isFrozen ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                    size: 15,
                    color: card.isFrozen ? const Color(0xFFDC2626) : AppColors.textDark,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      card.isFrozen ? 'Unfreeze Card' : 'Freeze Card',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: card.isFrozen ? const Color(0xFFDC2626) : AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label, WalletProvider provider) {
    final isSelected = provider.selectedFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textDark,
          ),
        ),
        selected: isSelected,
        selectedColor: const Color(0xFF064E3B),
        backgroundColor: Colors.white,
        side: BorderSide(color: isSelected ? const Color(0xFF064E3B) : const Color(0xFFE5E7EB)),
        showCheckmark: false,
        onSelected: (_) => provider.setFilter(key),
      ),
    );
  }
}

