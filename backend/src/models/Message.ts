import mongoose, { Document, Schema, Types } from 'mongoose';

export interface IMessage extends Document {
  taskId: Types.ObjectId;
  senderId: Types.ObjectId;
  recipientId: Types.ObjectId;
  content: string;
  type: 'TEXT' | 'IMAGE' | 'LOCATION' | 'SYSTEM' | 'VOICE';
  mediaUrl?: string;
  isRead: boolean;
  createdAt: Date;
}

const MessageSchema = new Schema<IMessage>(
  {
    taskId: { type: Schema.Types.ObjectId, ref: 'Task', required: true, index: true },
    senderId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    recipientId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    content: { type: String, default: '' },
    type: { type: String, enum: ['TEXT', 'IMAGE', 'LOCATION', 'SYSTEM', 'VOICE'], default: 'TEXT' },
    mediaUrl: { type: String },
    isRead: { type: Boolean, default: false }
  },
  { timestamps: true }
);

MessageSchema.index({ taskId: 1, createdAt: 1 });

export const Message = mongoose.model<IMessage>('Message', MessageSchema);
