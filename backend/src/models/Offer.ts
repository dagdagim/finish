import mongoose, { Document, Schema, Types } from 'mongoose';

export interface IOffer extends Document {
  taskId: Types.ObjectId;
  taskerId: Types.ObjectId;
  offeredAmount: number;
  note?: string;
  status: 'PENDING' | 'ACCEPTED' | 'REJECTED' | 'EXPIRED';
  createdAt: Date;
}

const OfferSchema = new Schema<IOffer>(
  {
    taskId: { type: Schema.Types.ObjectId, ref: 'Task', required: true, index: true },
    taskerId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    offeredAmount: { type: Number, required: true },
    note: { type: String, default: '' },
    status: { type: String, enum: ['PENDING', 'ACCEPTED', 'REJECTED', 'EXPIRED'], default: 'PENDING' }
  },
  { timestamps: true }
);

OfferSchema.index({ taskId: 1, taskerId: 1 }, { unique: true });

export const Offer = mongoose.model<IOffer>('Offer', OfferSchema);
