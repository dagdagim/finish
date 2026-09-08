import mongoose from 'mongoose';
import dotenv from 'dotenv';

dotenv.config();

// Disable buffering so queries never hang if the database is reconnecting
mongoose.set('bufferCommands', false);

const MONGODB_URL = process.env.MONGODB_URL || 'mongodb+srv://dagimbekele_db_user:TDu5Uw3qmife9GUx@cluster0.bjzjflu.mongodb.net/finish_marketplace?appName=Cluster0';

export const connectDB = async (): Promise<void> => {
  try {
    const conn = await mongoose.connect(MONGODB_URL, {
      serverSelectionTimeoutMS: 5000,
      connectTimeoutMS: 5000,
    });
    console.log(`[MongoDB] Connected successfully to host: ${conn.connection.host}, database: ${conn.connection.name}`);
  } catch (error: any) {
    console.warn('[MongoDB] Atlas connection note:', error.message || error);
  }
};
