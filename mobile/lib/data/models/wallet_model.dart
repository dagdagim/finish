import 'package:flutter/material.dart';

class VirtualCardModel {
  final String cardNumber;
  final String cardholderName;
  final String expiryDate;
  final String cvv;
  final String brand;
  final bool isFrozen;

  VirtualCardModel({
    this.cardNumber = '4242 5819 9021 4829',
    this.cardholderName = 'DANIEL KEBEDE',
    this.expiryDate = '08/29',
    this.cvv = '482',
    this.brand = 'VISA',
    this.isFrozen = false,
  });

  String get maskedCardNumber {
    final cleaned = cardNumber.replaceAll(' ', '');
    if (cleaned.length >= 16) {
      return '•••• •••• •••• ${cleaned.substring(12)}';
    }
    return '•••• •••• •••• 4829';
  }

  String get formattedCardNumber {
    final cleaned = cardNumber.replaceAll(' ', '');
    if (cleaned.length == 16) {
      return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 8)} ${cleaned.substring(8, 12)} ${cleaned.substring(12, 16)}';
    }
    return cardNumber;
  }

  String get last4 {
    final cleaned = cardNumber.replaceAll(' ', '');
    return cleaned.length >= 4 ? cleaned.substring(cleaned.length - 4) : '4829';
  }

  factory VirtualCardModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return VirtualCardModel();
    return VirtualCardModel(
      cardNumber: json['cardNumber']?.toString() ?? '4242 5819 9021 4829',
      cardholderName: (json['cardholderName']?.toString() ?? 'DANIEL KEBEDE').toUpperCase(),
      expiryDate: json['expiryDate']?.toString() ?? '08/29',
      cvv: json['cvv']?.toString() ?? '482',
      brand: json['cardBrand']?.toString() ?? json['brand']?.toString() ?? 'VISA',
      isFrozen: json['isFrozen'] == true,
    );
  }

  VirtualCardModel copyWith({
    String? cardNumber,
    String? cardholderName,
    String? expiryDate,
    String? cvv,
    String? brand,
    bool? isFrozen,
  }) {
    return VirtualCardModel(
      cardNumber: cardNumber ?? this.cardNumber,
      cardholderName: cardholderName ?? this.cardholderName,
      expiryDate: expiryDate ?? this.expiryDate,
      cvv: cvv ?? this.cvv,
      brand: brand ?? this.brand,
      isFrozen: isFrozen ?? this.isFrozen,
    );
  }
}

class TransactionModel {
  final String id;
  final int amount;
  final String currency;
  final String type;
  final String status;
  final String description;
  final String? taskTitle;
  final String? referenceId;
  final String cardLast4;
  final String? bankName;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.amount,
    this.currency = 'ETB',
    required this.type,
    required this.status,
    required this.description,
    this.taskTitle,
    this.referenceId,
    this.cardLast4 = '4829',
    this.bankName,
    required this.createdAt,
  });

  bool get isCredit => amount > 0;

  String get typeLabel {
    switch (type.toUpperCase()) {
      case 'TASK_EARNING':
        return 'Task Payout';
      case 'TIP_EARNING':
        return 'Customer Tip';
      case 'WITHDRAWAL':
        return 'Withdrawal';
      case 'TOP_UP':
        return 'Card Deposit';
      case 'CUSTOMER_PAYMENT':
        return 'Task Payment';
      case 'ESCROW_HOLD':
        return 'Escrow Hold';
      case 'ESCROW_RELEASE':
        return 'Escrow Release';
      case 'REFUND':
        return 'Refund';
      default:
        return 'Transaction';
    }
  }

  IconData get icon {
    switch (type.toUpperCase()) {
      case 'TASK_EARNING':
        return Icons.work_history_rounded;
      case 'TIP_EARNING':
        return Icons.star_rounded;
      case 'WITHDRAWAL':
        return Icons.arrow_upward_rounded;
      case 'TOP_UP':
        return Icons.add_card_rounded;
      case 'CUSTOMER_PAYMENT':
        return Icons.shopping_bag_outlined;
      case 'ESCROW_HOLD':
        return Icons.lock_outline_rounded;
      case 'ESCROW_RELEASE':
        return Icons.lock_open_rounded;
      case 'REFUND':
        return Icons.replay_rounded;
      default:
        return Icons.payments_outlined;
    }
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    int parsedAmount = 0;
    if (json['amount'] is num) {
      parsedAmount = (json['amount'] as num).toInt();
    }

    String? bank;
    if (json['payoutMethod'] is Map) {
      bank = json['payoutMethod']['bankName'] ?? json['payoutMethod']['type'];
    }

    return TransactionModel(
      id: json['_id'] ?? json['id'] ?? 'tx_${DateTime.now().millisecondsSinceEpoch}',
      amount: parsedAmount,
      currency: json['currency'] ?? 'ETB',
      type: json['type'] ?? 'TASK_EARNING',
      status: json['status'] ?? 'COMPLETED',
      description: json['description'] ?? 'Transaction',
      taskTitle: json['taskTitle'],
      referenceId: json['referenceId'] ?? 'REF-${(json['_id'] ?? '8921').toString().substring(0, 4).toUpperCase()}',
      cardLast4: json['cardLast4'] ?? '4829',
      bankName: bank,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

class WalletModel {
  final int availableBalance;
  final int pendingBalance;
  final int totalEarned;
  final int totalSpent;
  final String currency;
  final VirtualCardModel card;

  WalletModel({
    this.availableBalance = 2450,
    this.pendingBalance = 700,
    this.totalEarned = 18450,
    this.totalSpent = 3200,
    this.currency = 'ETB',
    VirtualCardModel? card,
  }) : card = card ?? VirtualCardModel();

  factory WalletModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return WalletModel();
    }
    return WalletModel(
      availableBalance: json['availableBalance'] is num ? (json['availableBalance'] as num).toInt() : 2450,
      pendingBalance: json['pendingBalance'] is num ? (json['pendingBalance'] as num).toInt() : 700,
      totalEarned: json['totalEarned'] is num ? (json['totalEarned'] as num).toInt() : 18450,
      totalSpent: json['totalSpent'] is num ? (json['totalSpent'] as num).toInt() : 3200,
      currency: json['currency'] ?? 'ETB',
      card: VirtualCardModel.fromJson(json),
    );
  }

  WalletModel copyWith({
    int? availableBalance,
    int? pendingBalance,
    int? totalEarned,
    int? totalSpent,
    String? currency,
    VirtualCardModel? card,
  }) {
    return WalletModel(
      availableBalance: availableBalance ?? this.availableBalance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      totalEarned: totalEarned ?? this.totalEarned,
      totalSpent: totalSpent ?? this.totalSpent,
      currency: currency ?? this.currency,
      card: card ?? this.card,
    );
  }
}
