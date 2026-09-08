import express from 'express';
import http from 'http';
import { Server as SocketIOServer } from 'socket.io';
import cors from 'cors';
import dotenv from 'dotenv';
import { connectDB } from './config/db';
import apiRouter from './routes/api';

dotenv.config();

const app = express();
const server = http.createServer(app);

const io = new SocketIOServer(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST', 'PATCH'],
    credentials: true
  },
  allowEIO3: true,
  transports: ['polling', 'websocket']
});


// Attach io instance to express app
app.set('io', io);

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// API Routes
app.use('/api/v1', apiRouter);

// Root route
app.get('/', (req, res) => {
  res.send({
    app: 'FINISH API',
    tagline: 'Small jobs. Real people. Done.',
    status: 'online',
    version: '1.0.0'
  });
});

// Real-Time Socket.IO Connections
io.on('connection', (socket) => {
  console.log(`[Socket.IO] Client connected: ${socket.id}`);

  socket.on('join_task', (taskId: string) => {
    if (!taskId) return;
    const cleanId = String(taskId).startsWith('task_') ? String(taskId).replace('task_', '') : String(taskId);
    socket.join(`task_${cleanId}`);
    socket.join(`task_${taskId}`);
    socket.join(String(taskId));
    console.log(`[Socket.IO] Socket ${socket.id} joined rooms for task: ${taskId}`);
  });

  socket.on('join_user', (userId: string) => {
    if (!userId) return;
    socket.join(`user_${userId}`);
    console.log(`[Socket.IO] Socket ${socket.id} joined private room user_${userId}`);
  });

  socket.on('join_thread', (data: { taskId: string, userA: string, userB: string }) => {
    if (!data || !data.taskId) return;
    const { taskId, userA, userB } = data;
    const cleanId = String(taskId).startsWith('task_') ? String(taskId).replace('task_', '') : String(taskId);
    const ids = [String(userA), String(userB)].sort();
    socket.join(`thread_${cleanId}_${ids[0]}_${ids[1]}`);
    socket.join(`thread_${taskId}_${ids[0]}_${ids[1]}`);
    console.log(`[Socket.IO] Socket ${socket.id} joined private thread room: thread_${cleanId}_${ids[0]}_${ids[1]}`);
  });

  socket.on('typing', (data) => {
    if (!data) return;
    const { taskId, userName, userId, recipientId } = data;
    const cleanId = String(taskId).startsWith('task_') ? String(taskId).replace('task_', '') : String(taskId);
    if (recipientId) {
      socket.to(`user_${recipientId}`).emit('user_typing', { taskId, userName, userId, recipientId });
    }
    if (userId && recipientId) {
      const ids = [String(userId), String(recipientId)].sort();
      socket.to(`thread_${cleanId}_${ids[0]}_${ids[1]}`).emit('user_typing', { taskId, userName, userId, recipientId });
      socket.to(`thread_${taskId}_${ids[0]}_${ids[1]}`).emit('user_typing', { taskId, userName, userId, recipientId });
    }
    io.emit('user_typing', { taskId, userName, userId, recipientId });
  });

  socket.on('stop_typing', (data) => {
    if (!data) return;
    const { taskId, userName, userId, recipientId } = data;
    const cleanId = String(taskId).startsWith('task_') ? String(taskId).replace('task_', '') : String(taskId);
    if (recipientId) {
      socket.to(`user_${recipientId}`).emit('user_stop_typing', { taskId, userName, userId, recipientId });
    }
    if (userId && recipientId) {
      const ids = [String(userId), String(recipientId)].sort();
      socket.to(`thread_${cleanId}_${ids[0]}_${ids[1]}`).emit('user_stop_typing', { taskId, userName, userId, recipientId });
      socket.to(`thread_${taskId}_${ids[0]}_${ids[1]}`).emit('user_stop_typing', { taskId, userName, userId, recipientId });
    }
    io.emit('user_stop_typing', { taskId, userName, userId, recipientId });
  });

  socket.on('task_status_update', (data) => {
    if (!data) return;
    const { taskId, status } = data;
    const cleanId = String(taskId).startsWith('task_') ? String(taskId).replace('task_', '') : String(taskId);
    io.to(`task_${cleanId}`).emit('status_changed', { taskId, status });
    io.to(`task_${taskId}`).emit('status_changed', { taskId, status });
  });

  socket.on('tasker_location', (data) => {
    if (!data) return;
    const { taskId, coordinates } = data;
    const cleanId = String(taskId).startsWith('task_') ? String(taskId).replace('task_', '') : String(taskId);
    io.to(`task_${cleanId}`).emit('tasker_moved', { taskId, coordinates });
    io.to(`task_${taskId}`).emit('tasker_moved', { taskId, coordinates });
  });

  socket.on('tasker_location_update', (data) => {
    if (!data) return;
    const { taskId } = data;
    const cleanId = String(taskId).startsWith('task_') ? String(taskId).replace('task_', '') : String(taskId);
    io.to(`task_${cleanId}`).emit('tasker_location_update', data);
    io.to(`task_${taskId}`).emit('tasker_location_update', data);
    io.emit('tasker_location_update', data);
  });

  socket.on('disconnect', () => {
    console.log(`[Socket.IO] Client disconnected: ${socket.id}`);
  });
});

const PORT = process.env.PORT || 5000;

server.listen(PORT, () => {
  console.log(`=============================================`);
  console.log(`  FINISH Backend Gateway running on port ${PORT}`);
  console.log(`  Target: Addis Ababa Micro-Task Marketplace`);
  console.log(`=============================================`);
  connectDB();
});
