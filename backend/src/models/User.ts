import mongoose, { Document, Schema } from 'mongoose';
import bcrypt from 'bcryptjs';

export interface IVerificationData {
  workExperienceYears: number;
  experienceDescription: string;
  educationalLevel: string;
  institutionName?: string;
  educationalCertificateUrl?: string;
  nationalIdNumber: string;
  nationalIdPhotoUrl?: string;
  nationalIdFrontUrl?: string;
  nationalIdBackUrl?: string;
  faceScanPhotoUrl?: string;
  driverLicensePhotoUrl?: string;
  emergencyContactName: string;
  emergencyContactPhone: string;
  primaryCategory: string;
  categoryAnswers: Record<string, any>;
  submittedAt?: Date;
  reviewedAt?: Date;
  adminNotes?: string;
}

export interface IUser extends Document {
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  passwordHash: string;
  avatarUrl?: string;
  role: 'customer' | 'tasker' | 'both' | 'admin';
  activeMode: 'customer' | 'tasker';
  isPhoneVerified: boolean;
  isIdentityVerified: boolean;
  verificationStatus: 'NOT_SUBMITTED' | 'PENDING' | 'APPROVED' | 'REJECTED';
  verificationData?: IVerificationData;
  isBlocked: boolean;
  rating: number;
  reviewCount: number;
  completedTasksCount: number;
  taskerProfile: {
    bio: string;
    skills: string[];
    serviceRadiusKm: number;
    isAvailableNow: boolean;
    level: 'STARTER' | 'ACTIVE' | 'PRO' | 'ELITE';
    completionRate: number;
    onTimeRate: number;
  };
  preferredLanguage: 'en' | 'am';
  createdAt: Date;
  comparePassword(candidate: string): Promise<boolean>;
}

const UserSchema = new Schema<IUser>(
  {
    firstName: { type: String, required: true, trim: true },
    lastName: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true, index: true },
    phone: { type: String, required: true, unique: true, trim: true, index: true },
    passwordHash: { type: String, required: true },
    avatarUrl: { type: String, default: '' },
    role: { type: String, enum: ['customer', 'tasker', 'both', 'admin'], default: 'both' },
    activeMode: { type: String, enum: ['customer', 'tasker'], default: 'customer' },
    isPhoneVerified: { type: Boolean, default: true },
    isIdentityVerified: { type: Boolean, default: false },
    verificationStatus: {
      type: String,
      enum: ['NOT_SUBMITTED', 'PENDING', 'APPROVED', 'REJECTED'],
      default: 'NOT_SUBMITTED'
    },
    verificationData: {
      workExperienceYears: { type: Number, default: 0 },
      experienceDescription: { type: String, default: '' },
      educationalLevel: { type: String, default: '' },
      institutionName: { type: String, default: '' },
      educationalCertificateUrl: { type: String, default: '' },
      nationalIdNumber: { type: String, default: '' },
      nationalIdPhotoUrl: { type: String, default: '' },
      nationalIdFrontUrl: { type: String, default: '' },
      nationalIdBackUrl: { type: String, default: '' },
      faceScanPhotoUrl: { type: String, default: '' },
      driverLicensePhotoUrl: { type: String, default: '' },
      emergencyContactName: { type: String, default: '' },
      emergencyContactPhone: { type: String, default: '' },
      primaryCategory: { type: String, default: 'delivery' },
      categoryAnswers: { type: Schema.Types.Mixed, default: {} },
      submittedAt: { type: Date },
      reviewedAt: { type: Date },
      adminNotes: { type: String, default: '' }
    },
    isBlocked: { type: Boolean, default: false },
    rating: { type: Number, default: 0.0 },
    reviewCount: { type: Number, default: 0 },
    completedTasksCount: { type: Number, default: 0 },
    taskerProfile: {
      bio: { type: String, default: 'Ready to help with reliable and high quality service.' },
      skills: { type: [String], default: ['Delivery', 'Errands'] },
      serviceRadiusKm: { type: Number, default: 10 },
      isAvailableNow: { type: Boolean, default: true },
      level: { type: String, enum: ['STARTER', 'ACTIVE', 'PRO', 'ELITE'], default: 'STARTER' },
      completionRate: { type: Number, default: 100 },
      onTimeRate: { type: Number, default: 100 }
    },
    preferredLanguage: { type: String, enum: ['en', 'am'], default: 'en' }
  },
  { timestamps: true }
);

UserSchema.methods.comparePassword = async function (candidate: string): Promise<boolean> {
  return bcrypt.compare(candidate, this.passwordHash);
};

export const User = mongoose.model<IUser>('User', UserSchema);
