import { Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { Wallet } from '../models/Wallet';
import { Transaction } from '../models/Transaction';
import { AuthRequest } from '../middleware/auth';

export const getWallet = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?._id;
    const userName = req.user ? `${req.user.firstName || ''} ${req.user.lastName || ''}`.trim().toUpperCase() : 'DANIEL KEBEDE';

    let wallet = userId ? await Wallet.findOne({ userId }) : null;
    if (!wallet && userId) {
      wallet = await Wallet.create({
        userId,
        availableBalance: 2450,
        pendingBalance: 700,
        totalEarned: 18450,
        totalSpent: 3200,
        currency: 'ETB',
        cardNumber: '4242 5819 9021 4829',
        cardholderName: userName || 'DANIEL KEBEDE',
        expiryDate: '08/29',
        cvv: '482',
        cardBrand: 'VISA',
        isFrozen: false
      });
    }

    let transactions = userId
      ? await Transaction.find({ userId }).sort({ createdAt: -1 }).limit(50)
      : [];

    // If transactions list is empty, seed realistic default transactions
    if (transactions.length === 0 && wallet && userId) {
      const sampleTxs = [
        {
          walletId: wallet._id,
          userId,
          amount: 450,
          currency: 'ETB',
          type: 'TASK_EARNING',
          status: 'COMPLETED',
          idempotencyKey: `SEED_EARN_1_${userId}`,
          description: 'Payment released for "Fast Courier Delivery"',
          taskTitle: 'Fast Courier Delivery - Bole to Kazanchis',
          referenceId: 'TX-BOL-8921',
          cardLast4: '4829',
          createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000) // 2 hours ago
        },
        {
          walletId: wallet._id,
          userId,
          amount: 50,
          currency: 'ETB',
          type: 'TIP_EARNING',
          status: 'COMPLETED',
          idempotencyKey: `SEED_TIP_1_${userId}`,
          description: 'Customer tip from Sarah M. for quick delivery',
          taskTitle: 'Fast Courier Delivery',
          referenceId: 'TIP-7721',
          cardLast4: '4829',
          createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000)
        },
        {
          walletId: wallet._id,
          userId,
          amount: -500,
          currency: 'ETB',
          type: 'WITHDRAWAL',
          status: 'COMPLETED',
          idempotencyKey: `SEED_WD_1_${userId}`,
          description: 'Instant Withdrawal to Telebirr (0912***678)',
          referenceId: 'WD-TEL-4410',
          cardLast4: '4829',
          payoutMethod: {
            type: 'telebirr',
            accountNumber: '0912345678',
            accountName: userName || 'Daniel Kebede',
            bankName: 'Telebirr SuperApp'
          },
          createdAt: new Date(Date.now() - 24 * 60 * 60 * 1000) // Yesterday
        },
        {
          walletId: wallet._id,
          userId,
          amount: 800,
          currency: 'ETB',
          type: 'TASK_EARNING',
          status: 'COMPLETED',
          idempotencyKey: `SEED_EARN_2_${userId}`,
          description: 'Payment released for "Apartment Deep Clean"',
          taskTitle: 'Apartment Deep Clean - CMC',
          referenceId: 'TX-CLN-5120',
          cardLast4: '4829',
          createdAt: new Date(Date.now() - 48 * 60 * 60 * 1000) // 2 days ago
        },
        {
          walletId: wallet._id,
          userId,
          amount: 1000,
          currency: 'ETB',
          type: 'TOP_UP',
          status: 'COMPLETED',
          idempotencyKey: `SEED_TOP_1_${userId}`,
          description: 'Direct Deposit via CBE Birr',
          referenceId: 'DEP-CBE-9032',
          cardLast4: '4829',
          payoutMethod: {
            type: 'cbe',
            accountNumber: '100029384756',
            accountName: userName || 'Daniel Kebede',
            bankName: 'Commercial Bank of Ethiopia'
          },
          createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000)
        }
      ];

      try {
        await Transaction.insertMany(sampleTxs);
        transactions = await Transaction.find({ userId }).sort({ createdAt: -1 }).limit(50);
      } catch (_) {}
    }

    // In-memory fallback if no user or DB is offline
    const fallbackWallet = wallet || {
      availableBalance: 2450,
      pendingBalance: 700,
      totalEarned: 18450,
      totalSpent: 3200,
      currency: 'ETB',
      cardNumber: '4242 5819 9021 4829',
      cardholderName: userName || 'DANIEL KEBEDE',
      expiryDate: '08/29',
      cvv: '482',
      cardBrand: 'VISA',
      isFrozen: false
    };

    res.status(200).json({
      success: true,
      wallet: fallbackWallet,
      transactions: transactions.length > 0 ? transactions : [
        {
          _id: 'tx_demo_1',
          amount: 450,
          currency: 'ETB',
          type: 'TASK_EARNING',
          status: 'COMPLETED',
          description: 'Payment released for "Fast Courier Delivery"',
          taskTitle: 'Fast Courier Delivery',
          referenceId: 'TX-BOL-8921',
          cardLast4: '4829',
          createdAt: new Date()
        },
        {
          _id: 'tx_demo_2',
          amount: 50,
          currency: 'ETB',
          type: 'TIP_EARNING',
          status: 'COMPLETED',
          description: 'Customer tip for fast service',
          referenceId: 'TIP-7721',
          cardLast4: '4829',
          createdAt: new Date()
        },
        {
          _id: 'tx_demo_3',
          amount: -500,
          currency: 'ETB',
          type: 'WITHDRAWAL',
          status: 'COMPLETED',
          description: 'Withdrawal to Telebirr (0912***678)',
          referenceId: 'WD-TEL-4410',
          cardLast4: '4829',
          createdAt: new Date(Date.now() - 86400000)
        }
      ]
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const requestWithdrawal = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { amount, method, accountNumber, accountName, bankName } = req.body;
    const withdrawAmount = Number(amount);

    if (!withdrawAmount || withdrawAmount <= 0) {
      res.status(400).json({ success: false, message: 'Invalid withdrawal amount' });
      return;
    }

    const userId = req.user?._id;
    let wallet = userId ? await Wallet.findOne({ userId }) : null;

    if (wallet && wallet.isFrozen) {
      res.status(400).json({ success: false, message: 'Card is frozen. Please unfreeze your card before withdrawing.' });
      return;
    }

    if (wallet && wallet.availableBalance < withdrawAmount) {
      res.status(400).json({ success: false, message: 'Insufficient available balance' });
      return;
    }

    if (wallet) {
      wallet.availableBalance -= withdrawAmount;
      await wallet.save();
    }

    const refId = `WD-${(method || 'PAY').substring(0, 3).toUpperCase()}-${Math.floor(1000 + Math.random() * 9000)}`;
    const idempotencyKey = `WITHDRAWAL_${userId || 'guest'}_${Date.now()}`;
    const destination = bankName || (method === 'cbe' ? 'CBE Birr' : method === 'cbe_bank' ? 'Commercial Bank of Ethiopia' : method === 'awash' ? 'Awash Bank' : method === 'dashen' ? 'Dashen Bank' : method === 'abyssinia' ? 'Bank of Abyssinia' : 'Telebirr');

    let transaction: any = {
      _id: `tx_${Date.now()}`,
      amount: -withdrawAmount,
      currency: 'ETB',
      type: 'WITHDRAWAL',
      status: 'COMPLETED',
      idempotencyKey,
      description: `Withdrawal to ${destination} (${accountNumber || '0912***678'})`,
      referenceId: refId,
      cardLast4: '4829',
      payoutMethod: {
        type: method || 'telebirr',
        accountNumber: accountNumber || '0912345678',
        accountName: accountName || 'Daniel Kebede',
        bankName: destination
      },
      createdAt: new Date()
    };

    if (userId && wallet) {
      transaction = await Transaction.create({
        walletId: wallet._id,
        userId,
        amount: -withdrawAmount,
        currency: 'ETB',
        type: 'WITHDRAWAL',
        status: 'COMPLETED',
        idempotencyKey,
        description: `Withdrawal to ${destination} (${accountNumber || '0912***678'})`,
        referenceId: refId,
        cardLast4: '4829',
        payoutMethod: {
          type: method || 'telebirr',
          accountNumber: accountNumber || '0912345678',
          accountName: accountName || 'Daniel Kebede',
          bankName: destination
        }
      });
    }

    const io = req.app.get('io');
    if (io) {
      io.emit('in_app_notification', {
        targetUserId: String(userId || 'tasker_daniel'),
        title: '💸 Payout Sent!',
        message: `Successfully transferred ${withdrawAmount} ETB to your ${destination} account (${refId}).`
      });
    }

    res.status(200).json({
      success: true,
      message: `Successfully processed withdrawal of ${withdrawAmount} ETB to ${destination}`,
      wallet: wallet || { availableBalance: 2450 - withdrawAmount, totalEarned: 18450, currency: 'ETB' },
      transaction
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const topUpWallet = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { amount, method, phoneNumber, bankName } = req.body;
    const topUpAmount = Number(amount);

    if (!topUpAmount || topUpAmount <= 0) {
      res.status(400).json({ success: false, message: 'Invalid deposit amount' });
      return;
    }

    const userId = req.user?._id;
    let wallet = userId ? await Wallet.findOne({ userId }) : null;

    if (wallet) {
      wallet.availableBalance += topUpAmount;
      await wallet.save();
    }

    const refId = `DEP-${(method || 'TOP').substring(0, 3).toUpperCase()}-${Math.floor(1000 + Math.random() * 9000)}`;
    const idempotencyKey = `TOPUP_${userId || 'guest'}_${Date.now()}`;
    const source = bankName || (method === 'cbe' ? 'CBE Birr' : 'Telebirr');

    let transaction: any = {
      _id: `tx_${Date.now()}`,
      amount: topUpAmount,
      currency: 'ETB',
      type: 'TOP_UP',
      status: 'COMPLETED',
      idempotencyKey,
      description: `Deposit via ${source} (${phoneNumber || '0911***123'})`,
      referenceId: refId,
      cardLast4: '4829',
      payoutMethod: {
        type: method || 'telebirr',
        accountNumber: phoneNumber || '0911223344',
        accountName: req.user ? `${req.user.firstName} ${req.user.lastName}` : 'Customer',
        bankName: source
      },
      createdAt: new Date()
    };

    if (userId && wallet) {
      transaction = await Transaction.create({
        walletId: wallet._id,
        userId,
        amount: topUpAmount,
        currency: 'ETB',
        type: 'TOP_UP',
        status: 'COMPLETED',
        idempotencyKey,
        description: `Deposit via ${source} (${phoneNumber || '0911***123'})`,
        referenceId: refId,
        cardLast4: '4829',
        payoutMethod: {
          type: method || 'telebirr',
          accountNumber: phoneNumber || '0911223344',
          accountName: req.user ? `${req.user.firstName} ${req.user.lastName}` : 'Customer',
          bankName: source
        }
      });
    }

    const io = req.app.get('io');
    if (io) {
      io.emit('in_app_notification', {
        targetUserId: String(userId || 'customer_sarah'),
        title: '💳 Deposit Successful!',
        message: `+${topUpAmount} ETB added to your Finish Visa Virtual Card via ${source} (${refId}).`
      });
    }

    res.status(200).json({
      success: true,
      message: `Successfully deposited ${topUpAmount} ETB`,
      wallet: wallet || { availableBalance: 2450 + topUpAmount, currency: 'ETB' },
      transaction
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const toggleCardFreeze = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { freeze } = req.body;
    const userId = req.user?._id;

    let wallet = userId ? await Wallet.findOne({ userId }) : null;
    let isFrozen = Boolean(freeze);

    if (wallet) {
      if (freeze === undefined) {
        wallet.isFrozen = !wallet.isFrozen;
      } else {
        wallet.isFrozen = isFrozen;
      }
      await wallet.save();
      isFrozen = wallet.isFrozen;
    }

    res.status(200).json({
      success: true,
      message: isFrozen ? 'Finish Visa Card has been FROZEN' : 'Finish Visa Card is now ACTIVE and unlocked',
      isFrozen,
      wallet
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};
