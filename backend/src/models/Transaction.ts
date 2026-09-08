import mongoose, { Document, Schema, Types } from 'mongoose';

export type TransactionType =
  | 'TASK_EARNING'
  | 'WITHDRAWAL'
  | 'TOP_UP'
  | 'CUSTOMER_PAYMENT'
  | 'TIP_EARNING'
  | 'PLATFORM_FEE'
  | 'ESCROW_HOLD'
  | 'ESCROW_RELEASE'
  | 'REFUND';

export interface ITransaction extends Document {
  walletId: Types.ObjectId;
  userId: Types.ObjectId;
  taskId?: Types.ObjectId;
  amount: number; // positive = credit, negative = debit
  currency: string;
  type: TransactionType;
  status: 'PENDING' | 'COMPLETED' | 'FAILED' | 'CANCELLED';
  idempotencyKey: string;
  description: string;
  taskTitle?: string;
  referenceId?: string;
  cardLast4?: string;
  payoutMethod?: {
    type: 'telebirr' | 'cbe' | 'cbe_bank' | 'awash' | 'dashen' | 'abyssinia' | 'bank';
    accountNumber: string;
    accountName: string;
    bankName?: string;
  };
  createdAt: Date;
}

const TransactionSchema = new Schema<ITransaction>(
  {
    walletId: { type: Schema.Types.ObjectId, ref: 'Wallet', required: true, index: true },
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    taskId: { type: Schema.Types.ObjectId, ref: 'Task' },
    amount: { type: Number, required: true },
    currency: { type: String, default: 'ETB' },
    type: {
      type: String,
      enum: [
        'TASK_EARNING',
        'WITHDRAWAL',
        'TOP_UP',
        'CUSTOMER_PAYMENT',
        'TIP_EARNING',
        'PLATFORM_FEE',
        'ESCROW_HOLD',
        'ESCROW_RELEASE',
        'REFUND'
      ],
      required: true
    },
    status: { type: String, enum: ['PENDING', 'COMPLETED', 'FAILED', 'CANCELLED'], default: 'COMPLETED' },
    idempotencyKey: { type: String, required: true, unique: true, index: true },
    description: { type: String, required: true },
    taskTitle: { type: String },
    referenceId: { type: String },
    cardLast4: { type: String, default: '4829' },
    payoutMethod: {
      type: { type: String, enum: ['telebirr', 'cbe', 'cbe_bank', 'awash', 'dashen', 'abyssinia', 'bank'] },
      accountNumber: String,
      accountName: String,
      bankName: String
    }
  },
  { timestamps: true }
);

export const Transaction = mongoose.model<ITransaction>('Transaction', TransactionSchema);
