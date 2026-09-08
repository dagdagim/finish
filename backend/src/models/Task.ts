import mongoose, { Document, Schema, Types } from 'mongoose';

export type TaskStatus =
  | 'DRAFT'
  | 'POSTED'
  | 'OPEN'
  | 'OFFERING'
  | 'ACCEPTED'
  | 'IN_PROGRESS'
  | 'SUBMITTED'
  | 'AWAITING_APPROVAL'
  | 'COMPLETED'
  | 'PAID'
  | 'CANCELLED'
  | 'DISPUTED';

export type TaskCategory =
  | 'delivery'
  | 'pickup'
  | 'shopping'
  | 'cleaning'
  | 'moving'
  | 'assembly'
  | 'home'
  | 'tech'
  | 'errands'
  | 'other';

export interface ITaskTimeline {
  status: TaskStatus;
  timestamp: Date;
  actorId?: Types.ObjectId;
  note?: string;
}

export interface ITask extends Document {
  customerId: Types.ObjectId;
  assignedTaskerId?: Types.ObjectId;
  title: string;
  category: TaskCategory;
  description: string;
  quantity: number;
  specialInstructions?: string;
  mediaUrls: string[];
  pickupLocation: {
    address: string;
    instructions?: string;
    coordinates: [number, number]; // [longitude, latitude]
  };
  dropoffLocation?: {
    address: string;
    instructions?: string;
    coordinates?: [number, number];
  };
  additionalStops?: Array<{
    address: string;
    instructions?: string;
  }>;
  schedule: {
    type: 'asap' | 'today' | 'tomorrow' | 'scheduled';
    windowText: string;
    date?: Date;
    windowStart?: string;
    windowEnd?: string;
  };
  pricing: {
    budget: number; // in ETB
    currency: string;
    pricingType: 'fixed' | 'negotiable';
    suggestedPrice: number;
    platformFee: number;
    finalPaidAmount?: number;
  };
  status: TaskStatus;
  timeline: ITaskTimeline[];
  proofOfWork?: {
    photos: string[];
    notes?: string;
    submittedAt: Date;
    gpsCoordinates?: [number, number];
  };
  adminRatings?: {
    taskerRating: number;
    taskerReview?: string;
    customerRating: number;
    customerReview?: string;
    ratedAt: Date;
  };
  customerRatingToTasker?: {
    rating: number;
    review?: string;
    tags?: string[];
    tipAmount?: number;
    ratedAt: Date;
  };
  startedAt?: Date;
  completedAt?: Date;
  offersCount: number;
  estimatedDurationMin: number;
  distanceKm: number;
  createdAt: Date;
  updatedAt: Date;
}

const TaskSchema = new Schema<ITask>(
  {
    customerId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    assignedTaskerId: { type: Schema.Types.ObjectId, ref: 'User', index: true },
    title: { type: String, required: true, trim: true },
    category: {
      type: String,
      enum: ['delivery', 'pickup', 'shopping', 'cleaning', 'moving', 'assembly', 'home', 'tech', 'errands', 'other'],
      required: true,
      index: true
    },
    description: { type: String, required: true },
    quantity: { type: Number, default: 1 },
    specialInstructions: { type: String, default: '' },
    mediaUrls: { type: [String], default: [] },
    pickupLocation: {
      address: { type: String, required: true },
      instructions: { type: String, default: '' },
      coordinates: { type: [Number], index: '2dsphere', required: true } // [lng, lat]
    },
    dropoffLocation: {
      address: { type: String },
      instructions: { type: String, default: '' },
      coordinates: { type: [Number], index: '2dsphere' }
    },
    additionalStops: [
      {
        address: String,
        instructions: String
      }
    ],
    schedule: {
      type: { type: String, enum: ['asap', 'today', 'tomorrow', 'scheduled'], default: 'today' },
      windowText: { type: String, default: 'Today · Before 5 PM' },
      date: Date,
      windowStart: String,
      windowEnd: String
    },
    pricing: {
      budget: { type: Number, required: true },
      currency: { type: String, default: 'ETB' },
      pricingType: { type: String, enum: ['fixed', 'negotiable'], default: 'fixed' },
      suggestedPrice: { type: Number, default: 450 },
      platformFee: { type: Number, default: 50 },
      finalPaidAmount: Number
    },
    status: {
      type: String,
      enum: [
        'DRAFT',
        'POSTED',
        'OPEN',
        'OFFERING',
        'ACCEPTED',
        'IN_PROGRESS',
        'SUBMITTED',
        'AWAITING_APPROVAL',
        'COMPLETED',
        'PAID',
        'CANCELLED',
        'DISPUTED'
      ],
      default: 'OPEN',
      index: true
    },
    timeline: [
      {
        status: { type: String, required: true },
        timestamp: { type: Date, default: Date.now },
        actorId: { type: Schema.Types.ObjectId, ref: 'User' },
        note: { type: String }
      }
    ],
    proofOfWork: {
      photos: { type: [String], default: [] },
      notes: { type: String },
      submittedAt: { type: Date },
      gpsCoordinates: { type: [Number] }
    },
    adminRatings: {
      taskerRating: { type: Number },
      taskerReview: { type: String },
      customerRating: { type: Number },
      customerReview: { type: String },
      ratedAt: { type: Date }
    },
    customerRatingToTasker: {
      rating: { type: Number },
      review: { type: String },
      tags: { type: [String], default: [] },
      tipAmount: { type: Number, default: 0 },
      ratedAt: { type: Date }
    },
    startedAt: { type: Date },
    completedAt: { type: Date },
    offersCount: { type: Number, default: 0 },
    estimatedDurationMin: { type: Number, default: 35 },
    distanceKm: { type: Number, default: 2.5 }
  },
  { timestamps: true }
);

TaskSchema.index({ status: 1, category: 1, createdAt: -1 });

export const Task = mongoose.model<ITask>('Task', TaskSchema);
