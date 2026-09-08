import mongoose, { Document, Schema, Types } from 'mongoose';

export interface IReview extends Document {
  taskId: Types.ObjectId;
  reviewerId: Types.ObjectId;
  revieweeId: Types.ObjectId;
  rating: number; // 1 - 5
  tags: string[];
  comment: string;
  createdAt: Date;
}

const ReviewSchema = new Schema<IReview>(
  {
    taskId: { type: Schema.Types.ObjectId, ref: 'Task', required: true, index: true },
    reviewerId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    revieweeId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    rating: { type: Number, required: true, min: 1, max: 5 },
    tags: { type: [String], default: [] },
    comment: { type: String, default: '' }
  },
  { timestamps: true }
);

ReviewSchema.index({ taskId: 1, reviewerId: 1 }, { unique: true });

export const Review = mongoose.model<IReview>('Review', ReviewSchema);

export interface IDispute extends Document {
  taskId: Types.ObjectId;
  raisedBy: Types.ObjectId;
  reason: string;
  description: string;
  evidenceUrls: string[];
  status: 'OPEN' | 'UNDER_REVIEW' | 'RESOLVED' | 'CLOSED';
  resolution?: string;
  resolvedAt?: Date;
}

const DisputeSchema = new Schema<IDispute>(
  {
    taskId: { type: Schema.Types.ObjectId, ref: 'Task', required: true, index: true },
    raisedBy: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    reason: { type: String, required: true },
    description: { type: String, required: true },
    evidenceUrls: { type: [String], default: [] },
    status: { type: String, enum: ['OPEN', 'UNDER_REVIEW', 'RESOLVED', 'CLOSED'], default: 'OPEN' },
    resolution: String,
    resolvedAt: Date
  },
  { timestamps: true }
);

export const Dispute = mongoose.model<IDispute>('Dispute', DisputeSchema);
