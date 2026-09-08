import mongoose, { Document, Schema, Types } from 'mongoose';

export interface IWallet extends Document {
  userId: Types.ObjectId;
  availableBalance: number;
  pendingBalance: number;
  totalEarned: number;
  totalSpent: number;
  currency: string;
  // Virtual Visa / Mastercard Properties
  cardNumber: string;
  cardholderName: string;
  expiryDate: string;
  cvv: string;
  cardBrand: 'VISA' | 'MASTERCARD';
  isFrozen: boolean;
  updatedAt: Date;
}

const WalletSchema = new Schema<IWallet>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, unique: true, index: true },
    availableBalance: { type: Number, default: 2450 },
    pendingBalance: { type: Number, default: 700 },
    totalEarned: { type: Number, default: 18450 },
    totalSpent: { type: Number, default: 3200 },
    currency: { type: String, default: 'ETB' },
    cardNumber: { type: String, default: '4242 5819 9021 4829' },
    cardholderName: { type: String, default: 'FINISH MEMBER' },
    expiryDate: { type: String, default: '08/29' },
    cvv: { type: String, default: '482' },
    cardBrand: { type: String, enum: ['VISA', 'MASTERCARD'], default: 'VISA' },
    isFrozen: { type: Boolean, default: false }
  },
  { timestamps: true }
);

export const Wallet = mongoose.model<IWallet>('Wallet', WalletSchema);
