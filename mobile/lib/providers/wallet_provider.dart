import 'package:flutter/material.dart';
import '../data/models/wallet_model.dart';
import '../data/services/api_service.dart';

class WalletProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  WalletModel _wallet = WalletModel();
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String _selectedFilter = 'ALL';

  WalletModel get wallet => _wallet;
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String get selectedFilter => _selectedFilter;

  List<TransactionModel> get filteredTransactions {
    if (_selectedFilter == 'ALL') return _transactions;
    if (_selectedFilter == 'EARNINGS') {
      return _transactions.where((t) => t.type == 'TASK_EARNING' || t.type == 'TIP_EARNING').toList();
    }
    if (_selectedFilter == 'WITHDRAWALS') {
      return _transactions.where((t) => t.type == 'WITHDRAWAL').toList();
    }
    if (_selectedFilter == 'DEPOSITS') {
      return _transactions.where((t) => t.type == 'TOP_UP').toList();
    }
    if (_selectedFilter == 'ESCROW') {
      return _transactions.where((t) => t.type == 'ESCROW_HOLD' || t.type == 'ESCROW_RELEASE' || t.type == 'CUSTOMER_PAYMENT').toList();
    }
    return _transactions;
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  Future<void> fetchWallet() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.getWallet();
      _wallet = res['wallet'];
      _transactions = res['transactions'];
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> withdraw({
    required int amount,
    required String method,
    required String accountNumber,
    String? accountName,
    String? bankName,
  }) async {
    if (amount <= 0 || amount > _wallet.availableBalance) return false;
    if (_wallet.card.isFrozen) return false;

    final destination = bankName ?? (method == 'cbe' ? 'CBE Birr' : method == 'cbe_bank' ? 'Commercial Bank of Ethiopia' : method == 'awash' ? 'Awash Bank' : method == 'dashen' ? 'Dashen Bank' : method == 'abyssinia' ? 'Bank of Abyssinia' : 'Telebirr');
    final refId = 'WD-${method.substring(0, 3).toUpperCase()}-${DateTime.now().millisecondsSinceEpoch % 10000}';

    _wallet = _wallet.copyWith(
      availableBalance: _wallet.availableBalance - amount,
    );

    _transactions.insert(
      0,
      TransactionModel(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        amount: -amount,
        type: 'WITHDRAWAL',
        status: 'COMPLETED',
        description: 'Instant Withdrawal to $destination ($accountNumber)',
        referenceId: refId,
        cardLast4: _wallet.card.last4,
        bankName: destination,
        createdAt: DateTime.now(),
      ),
    );

    notifyListeners();

    await _api.requestWithdrawal(
      amount: amount,
      method: method,
      accountNumber: accountNumber,
      accountName: accountName,
      bankName: bankName,
    );

    return true;
  }

  Future<bool> topUp({
    required int amount,
    required String method,
    required String phoneNumber,
    String? bankName,
  }) async {
    if (amount <= 0) return false;

    final source = bankName ?? (method == 'cbe' ? 'CBE Birr' : 'Telebirr');
    final refId = 'DEP-${method.substring(0, 3).toUpperCase()}-${DateTime.now().millisecondsSinceEpoch % 10000}';

    _wallet = _wallet.copyWith(
      availableBalance: _wallet.availableBalance + amount,
    );

    _transactions.insert(
      0,
      TransactionModel(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        type: 'TOP_UP',
        status: 'COMPLETED',
        description: 'Direct Deposit via $source ($phoneNumber)',
        referenceId: refId,
        cardLast4: _wallet.card.last4,
        bankName: source,
        createdAt: DateTime.now(),
      ),
    );

    notifyListeners();

    await _api.topUpWallet(
      amount: amount,
      method: method,
      phoneNumber: phoneNumber,
      bankName: bankName,
    );

    return true;
  }

  Future<void> toggleFreezeCard() async {
    final nextState = !_wallet.card.isFrozen;
    _wallet = _wallet.copyWith(
      card: _wallet.card.copyWith(isFrozen: nextState),
    );
    notifyListeners();

    await _api.toggleCardFreeze(freeze: nextState);
  }
}
